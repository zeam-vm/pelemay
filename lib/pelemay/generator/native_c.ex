defmodule Pelemay.Generator.Native_C do
  alias Pelemay.Db
  alias Pelemay.Generator

  def generate(module) do
    Generator.libc(module) |> write(module)
  end

  defp write(file, module) do
    str =
      init_nif()
      |> basic()
      |> generate_host()
      |> erl_nif_init(module)

    file |> File.write(str)
  end

  defp generate_host(str) do
    definition_func =
      Db.get_arguments()
      |> Enum.map(&(&1 |> generate_host_code))
      |> to_str_code

    str <> definition_func <> func_list()
  end

  defp generate_host_code([name, _]) do
    """
    static ERL_NIF_TERM
    #{name}(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]){

    //iroiro
    cl_device_id device_id = NULL;
    cl_context context = NULL;
    cl_command_queue command_queue = NULL;
    cl_mem memobj = NULL;
    cl_mem memosize = NULL;
    cl_program program = NULL;
    cl_kernel kernel = NULL;
    cl_platform_id platform_id = NULL;
    cl_uint ret_num_devices, ret_num_platforms;
    cl_int ret;
    
    //get size of input array
    unsigned int size;
    enif_get_list_length(env, argv[0], &size);
    
    //vector for C
    long *vec;
    vec = (long *)malloc( size* sizeof(long));

    if (__builtin_expect((enif_get_long_vec_from_list(env, argv[0], vec, size) == fail), false)) {
        return enif_make_badarg(env);
    }
    FILE *fp;
    char fileName[] = "#{Generator.libcl_func(name)}";
    char *source_str;
    size_t source_size;
    
    fp = fopen(fileName, "r");
    if(!fp) {
        exit(1);
    }
    source_str = (char*)malloc(MAX_SOURCE_SIZE);
    source_size = fread(source_str, 1, MAX_SOURCE_SIZE, fp);
    fclose(fp);
    
    ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
    ret = clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_GPU, 1, &device_id, &ret_num_devices);
    
    context = clCreateContext(NULL, 1, &device_id, NULL, NULL, &ret);
    
    command_queue = clCreateCommandQueue(context, device_id, 0, &ret);
    
    memobj = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(long)*size, NULL, &ret);
    memosize = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(int), NULL, &ret);
    
    ret = clEnqueueWriteBuffer(command_queue, memobj, CL_TRUE, 0, sizeof(long)*size, vec, 0, NULL, NULL);
    ret = clEnqueueWriteBuffer(command_queue, memosize, CL_TRUE, 0, sizeof(int), &size, 0, NULL, NULL);
    
    program = clCreateProgramWithSource(context, 1, (const char **)&source_str, (const size_t *)&source_size, &ret);
    
    ret = clBuildProgram(program, 1, &device_id, NULL, NULL, NULL);
    
    kernel = clCreateKernel(program, "#{name}", &ret);
    
    ret = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&memobj);
    ret = clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&memosize);
    
    size_t local_item_size = LOCAL_SIZE;
    size_t global_item_size = ITEM_SIZE;
    
    //ret = clEnqueueTask(command_queue, kernel, 0, NULL, NULL);
    
    ret = clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL, &global_item_size, &local_item_size, 0, NULL, NULL);
    
    ret = clEnqueueReadBuffer(command_queue, memobj, CL_TRUE, 0, sizeof(long)*size, vec, 0, NULL, NULL);
    
    ret = clFlush(command_queue);
    ret = clFinish(command_queue);
    ret = clReleaseKernel(kernel);
    ret = clReleaseProgram(program);
    ret = clReleaseMemObject(memobj);
    ret = clReleaseCommandQueue(command_queue);
    ret = clReleaseContext(context);
    ERL_NIF_TERM list = enif_make_list_from_long_vec(env, vec, size);
  
    free(source_str);
    free(vec);
    
    return list;
    
    }
    """
  end

  defp to_str_code(list) when list |> is_list do
    list
    |> Enum.reduce(fn x, acc ->  x<>acc end) 
  end

  defp func_list do
    fl =
      Db.get_arguments()
      |> Enum.map(&(&1 |> hd ))
      |> Enum.reduce(
          "",
          fn x, acc ->
            str = x |> erl_nif_func
            acc <> "#{str},"
          end
      )
    
    """
    static
    ErlNifFunc nif_funcs[] =
    {
      // {erl_function_name, erl_function_arity, c_function}
      #{fl}
    };
    """
  end

  defp erl_nif_init(str, module) do
    str <>
      """
      ERL_NIF_INIT(Elixir.#{Generator.nif_module(module)}, nif_funcs, &load, &reload, &upgrade, &unload)
      """
  end

  defp erl_nif_func(name) do
    ~s/{"#{name}", 1, #{name}}/
  end

  defp init_nif do
    """
    #define CL_SILENCE_DEPRECATION
    #include <stdio.h>
    #include <stdlib.h>
    #ifdef __APPLE__
    #include <OpenCL/opencl.h>
    #else
    #include <CL/cl.h>
    #endif 
    #include <erl_nif.h>
    #include <string.h>
    #include <stdbool.h>
    #include <time.h>

    #define MAX_SOURCE_SIZE 0x100000
    #define ITEM_SIZE 10000
    #define LOCAL_SIZE 200


    ERL_NIF_TERM atom_struct;
    ERL_NIF_TERM atom_range;
    ERL_NIF_TERM atom_first;
    ERL_NIF_TERM atom_last;

    static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info);
    static void unload(ErlNifEnv *env, void *priv);
    static int reload(ErlNifEnv *env, void **priv, ERL_NIF_TERM info);
    static int upgrade(ErlNifEnv *env, void **priv, void **old_priv, ERL_NIF_TERM info);

    static int
    load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
    {
    atom_struct = enif_make_atom(env, "__struct__");
    atom_range = enif_make_atom(env, "Elixir.Range");
    atom_first = enif_make_atom(env, "first");
    atom_last = enif_make_atom(env, "last");
    return 0;
    }

    static void
    unload(ErlNifEnv *env, void *priv)
    {
    }

    static int
    reload(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
    {
    return 0;
    }

    static int
    upgrade(ErlNifEnv *env, void **priv, void **old_priv, ERL_NIF_TERM info)
    {
    return load(env, priv, info);
    }
    """
  end

  defp basic(str) do
    {:ok, ret} = File.read(__DIR__ <> "/native/basic_CL.c")

    str <> ret
  end


end