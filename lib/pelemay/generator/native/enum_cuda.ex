defmodule Pelemay.Generator.Native.EnumCuda do
  alias Pelemay.Generator.Native.Util, as: Util
  alias Pelemay.Db

  def map(info) do
    %{
      nif_name: nif_name,
      args: [
        func: %{
          args: args,
          operators: operators
        }
      ]
    } = info

    expr_d = Util.make_expr(operators, args, "double")
    expr_l = Util.make_expr(operators, args, "long")

    Util.push_impl_info(info, true)

    """
    #ifdef __cplusplus
    }
    #endif

    __global__ void #{nif_name}_map_double_kernel(size_t vec_l, double* vec_double)
    {
      int i = blockIdx.x * blockDim.x + threadIdx.x;
      if(i < vec_l){
        vec_double[i] = #{expr_d};
      }
    }

    __global__ void #{nif_name}_map_long_kernel(size_t vec_l, ErlNifSInt64* vec_long)
    {
      int i = blockIdx.x * blockDim.x + threadIdx.x;
      if(i < vec_l){
        vec_long[i] = #{expr_l};
      }
    }

    static cudaError_t #{nif_name}_map_double_host(size_t vec_l, double* vec_double)
    {
      cudaError_t error_code;
      double* dev_vec_double;
      error_code = cudaMalloc(&dev_vec_double, vec_l * sizeof(vec_double[0]));
      if (__builtin_expect((error_code != cudaSuccess), false)) {
        // the occured error may be cudaErrorInvalidValue or cudaErrorMemoryAllocation.
        fprintf(stderr, "error double_host_cudaMalloc\\n");
        return error_code;
      }
      error_code = cudaMemcpy(dev_vec_double, vec_double, vec_l * sizeof(vec_double[0]), cudaMemcpyHostToDevice);
      if (__builtin_expect((error_code != cudaSuccess), false)) {
        // the occured error may be cudaErrorInvalidValue or cudaErrorInvalidMemcpyDirection.
        fprintf(stderr, "error double_host_cudaMemcpy_1\\n");
        return error_code;
      }

      #{nif_name}_map_double_kernel <<< (vec_l + 255)/256, 256 >>> (vec_l, dev_vec_double);

      error_code = cudaMemcpy(vec_double, dev_vec_double, vec_l * sizeof(vec_double[0]), cudaMemcpyDeviceToHost);
      if (__builtin_expect((error_code != cudaSuccess), false)) {
        // the occured error may be cudaErrorInvalidValue or cudaErrorInvalidMemcpyDirection.
        fprintf(stderr, "error double_host_cudaMemcpy_2\\n");
        return error_code;
      }
      error_code = cudaFree(dev_vec_double);
      if (__builtin_expect((error_code != cudaSuccess), false)) {
        // the occured error may be cudaErrorInvalidValue.
        fprintf(stderr, "error double_host_cudaFree\\n");
        return error_code;
      }
      return cudaSuccess;
    }

    static cudaError_t #{nif_name}_map_long_host(size_t vec_l, ErlNifSInt64* vec_long)
    {
      cudaError_t error_code;
      ErlNifSInt64* dev_vec_long;

      error_code = cudaMalloc(&dev_vec_long, vec_l * sizeof(vec_long[0]));
      if (__builtin_expect((error_code != cudaSuccess), false)) {
        // the occured error may be cudaErrorInvalidValue or cudaErrorMemoryAllocation.
        fprintf(stderr, "error long_host_cudaMalloc\\n");
        return error_code;
      }
      error_code = cudaMemcpy(dev_vec_long, vec_long, vec_l * sizeof(vec_long[0]), cudaMemcpyHostToDevice);      
      if (__builtin_expect((error_code != cudaSuccess), false)) {
        // the occured error may be cudaErrorInvalidValue or cudaErrorInvalidMemcpyDirection.
        fprintf(stderr, "error long_host_cudaMemcpy_1\\n");
        return error_code;
      }

      #{nif_name}_map_long_kernel <<< (vec_l + 255)/256, 256 >>> (vec_l, dev_vec_long);

      error_code = cudaMemcpy(vec_long, dev_vec_long, vec_l * sizeof(vec_long[0]), cudaMemcpyDeviceToHost);
      if (__builtin_expect((error_code != cudaSuccess), false)) {
        // the occured error may be cudaErrorInvalidValue or cudaErrorInvalidMemcpyDirection.
        fprintf(stderr, "error long_host_cudaMemcpy_2\\n");        
        return error_code;
      }
      error_code = cudaFree(dev_vec_long);
      if (__builtin_expect((error_code != cudaSuccess), false)) {
        // the occured error may be cudaErrorInvalidValue.
        fprintf(stderr, "error long_host_cudaFree\\n");
        return error_code;
      }
      return cudaSuccess;
    }

    #ifdef __cplusplus
    extern "C" {
    #endif

    static ERL_NIF_TERM
    #{nif_name}(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      cudaError_t error_code;

      if (__builtin_expect((argc != 1), false)) {
        return enif_make_badarg(env);
      }
      ErlNifSInt64 *vec_long;
      size_t vec_l;
      double *vec_double;
      if (__builtin_expect((enif_get_int64_vec_from_list(env, argv[0], &vec_long, &vec_l) == fail), false)) {
        if (__builtin_expect((enif_get_double_vec_from_list(env, argv[0], &vec_double, &vec_l) == fail), false)) {
          return enif_make_badarg(env);
        }
        error_code = #{nif_name}_map_double_host(vec_l, vec_double);
        if(__builtin_expect((error_code != cudaSuccess), false)) {
          fprintf(stderr, "%s\\n", cudaGetErrorName(error_code));
          return enif_make_badarg(env);
        }
        return enif_make_list_from_double_vec(env, vec_double, vec_l);
      }
      error_code = #{nif_name}_map_long_host(vec_l, vec_long);
      if(__builtin_expect((error_code != cudaSuccess), false)) {
        fprintf(stderr, "%s\\n", cudaGetErrorName(error_code));
        return enif_make_badarg(env);
      }
      return enif_make_list_from_int64_vec(env, vec_long, vec_l);
    }
    """
  end

  def chunk_every(info) do
    %{
      nif_name: nif_name,
      module: _,
      function: _,
      arg_num: _,
      args: _
    } = info

    {:ok, ret} = File.read(__DIR__ <> "/enum.c")

    Map.update(info, :impl, nil, fn _ -> true end)
    |> Map.update(:arg_num, nil, fn _ -> 2 end)
    |> Db.register()

    String.replace(ret, "chunk_every", "#{nif_name}")
  end

  # Add here
  def sort(info) do
    Util.push_impl_info(info, false)

    nil
  end

  def filter(info) do
    Util.push_impl_info(info, false)

    nil
  end
end
