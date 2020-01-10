defmodule Pelemay.Generator.Native_CL do
  alias Pelemay.Db
  alias Pelemay.Generator
  
  # generate OpenCl Code
  def generate() do
    generate_functions() 
  end

  # generate kernel code
  defp generate_functions do
    Db.get_functions()
    |> Enum.map(&(&1 |> generate_function))
  end

  # generate each kernel code
  defp generate_function([func_info]) do
    %{
      nif_name: nif_name,
      module: _,
      function: _,
      arg_num: _,
      args: _,
      operators: _
    } = func_info

    enum_map(func_info)
    |> write_kernel(nif_name)
  end

  defp write_kernel(str, nif_name) do
    Generator.libcl_func(nif_name) |> File.write(str)
  end

  defp enclosure(str) do
    "(#{str})"
  end

  defp make_expr(operators, args, type)
       when is_list(operators) and is_list(args) do
    args = args |> to_string(:args, type)

    operators = operators |> to_string(:op)

    last_arg = List.last(args)

    expr =
      Enum.zip(args, operators)
      |> Enum.reduce("", &make_expr/2)

    if type == "double" && String.contains?(expr, "%") do
      "(vec_double[i])"
    else
      enclosure(expr <> last_arg)
    end
  end

  defp make_expr({arg, operator}, acc) do
    enclosure(acc <> arg) <> operator
  end

  defp to_string(args, :args, "double") do
    args
    |> Enum.map(&(&1 |> arg_to_string("double")))
  end

  defp to_string(args, :args, type) do
    args
    |> Enum.map(&(&1 |> arg_to_string(type)))
  end

  defp to_string(operators, :op) do
    operators
    |> Enum.map(&(&1 |> operator_to_string))
  end

  defp arg_to_string(arg, type) do
    case arg do
      {:&, _meta, [1]} -> "vec[gid+gsize*i]"
      {_, _, nil} -> "vec[gid+gsize*i]"
      other -> "#{other}"
    end
  end

  defp operator_to_string(operator) do
    case operator do
      :rem -> "%"
      other -> other |> to_string
    end
  end

  # defp enum_map_(str, operator, num) 
  defp enum_map(%{nif_name: nif_name, args: args, operators: operators}) do
    expr_double = make_expr(operators, args, "double")
    expr_long = make_expr(operators, args, "long")

    # expr_d = case operators do
    #   :% -> ""
    #   _ -> "#{str_operator}  #{args}"
    # end

    # expr_l = "#{str_operator} (long)#{args}"

    """
    __kernel void #{nif_name}_long(__global long *vec,__global int *size) {
     size_t gid = get_global_id(0);
     size_t gsize = get_global_size(0);
     int rep, i;
     rep = ((*size)-gid)/gsize + 1;
     for(i=0;i<rep;i++){
       vec[gid+gsize*i] = #{expr_long} 
      }
    }

    __kernel void #{nif_name}_double(__global double *vec,__global int *size) {
     size_t gid = get_global_id(0);
     size_t gsize = get_global_size(0);
     int rep, i;
     rep = ((*size)-gid)/gsize + 1;
     for(i=0;i<rep;i++){
       vec[gid+gsize*i] = #{expr_double} 
      }
    }
    """
  end
  
end