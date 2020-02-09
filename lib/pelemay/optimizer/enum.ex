defmodule Optimizer.Enum do
  alias Pelemay.Db

  require Logger

  # Add supported code
  def env do
    [:map, :sort]
  end

  def init(ast) do
    high_order_func = which_enum_func?(ast)

    {_enum_func, _meta, arg_func} = ast
    optimized_ast = parallelize_term(high_order_func, arg_func, ast)

    # optimized_ast = case high_order_func do
    #   [] ->
    #     str = Macro.to_string(ast)
    #     Logger.warn("Sorry, #{str} cannot accelerated yet.")
    #     ast

    #   _ ->
    #     {_enum_func, _meta, arg_func} = ast
    #     parallelize_term(support_hof, arg_func, ast)
    # end

    case optimized_ast do
      {:ok, opt_ast} -> {ast, opt_ast}
      {:error, ast} -> ast
    end
  end

  defp which_enum_func?(ast) do
    SumMag.include_specified_functions?(ast, :Enum, env())
  end

  defp parallelize_term([], _, ast), do: {:error, ast}
  defp parallelize_term([{key, 1}], func, ast) do
    res =
      Analyzer.supported?(func)

    call_nif(res, key)
  end

  defp parallelize_term([{key, arity}], func, ast) do
    parallelize_term([{key, arity - 1}], func, ast)
  end

  defp call_nif({:ok, asm}, key) do
    %{
      operators: operators,
      args: args
    } = asm

    func_name = Optimizer.AFunction.generate_function_name(key, asm)

    case Db.validate(func_name) do
      false ->
        nil

      other ->
        info = %{
          module: :Enum,
          function: key,
          nif_name: func_name,
          arg_num: 1,
          args: args,
          operators: operators,
          impl: nil
        }

        Db.register(info)
    end

    func_name = func_name |> String.to_atom()

    {:ok, quote do
      # try do
      ReplaceModule.unquote(func_name)
      # rescue
      #   e in RuntimeError -> ast
      # end
    end}
  end

  defp call_nif({:error, _}), do: :error
end
