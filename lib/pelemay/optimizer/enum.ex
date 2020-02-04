defmodule Optimizer.Enum do
  alias Pelemay.Db

  require Logger

  def env do
    [:map, :chunk_every]
  end

  def init(ast) do
    high_order_func = which_enum_func?(ast)

    support_hof = env()
    |> Enum.map(& Keyword.take(high_order_func, [&1]))
    |> List.flatten()

    case support_hof do
      [{:map, x}] -> # 別関数があってもここには引っかからない
        {_enum_map, _meta, arg_func} = ast
        parallelize_term(support_hof, arg_func)

      # Add HERE

      _ -> 
        str = Macro.to_string(ast)
        Logger.warn("Sorry, #{str} cannot accelerated yet.")
        ast
    end
  end

  defp which_enum_func?(ast) do
    SumMag.include_specified_functions?(ast, :Enum, env())
  end

  defp parallelize_term([{key, 1}], func) do
    res = Analyzer.supported?(func)

    call_nif(res, key)
  end

  defp parallelize_term([{key, x}], func) do
    parallelize_term([{key, x-1}], func)
  end

  defp call_nif({:ok, asm}, key) do
    %{
      operators: operators,
      args: args
    } = asm

    func_name = Optimizer.AFunction.generate_function_name(:map, asm)

    case Db.validate(func_name) do
      false ->
        nil

      other ->
        # plan to fix this data
        info = %{
          module: :enum,
          function: key,
          nif_name: func_name,
          arg_num: 1,
          args: args,
          operators: operators
        }

        Db.register(info)
    end

    func_name = func_name |> String.to_atom()

    quote do: ReplaceModule.unquote(func_name)
  end

  defp call_nif({:error, asm}, _atom) do
    asm
  end
end
