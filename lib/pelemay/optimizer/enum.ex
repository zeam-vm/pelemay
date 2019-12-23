defmodule Optimizer.Enum do
  import Analyzer
  alias Pelemay.Db

  require Logger

  def env do
    [:map, :chunk_every]
  end

  def parallelize_term({
        {_, _, higher_order_func},
        %{map: _x}
      }) do
    higher_order_func
    |> supported?()
    |> call_nif(:map)
  end

  def parallelize_term({quoted, _}) do
    str = Macro.to_string(quoted)

    Logger.warn("Sorry, #{str} cannot accelerated yet.")
    quoted
  end

  def parallelize_term(other) do
    other
    |> which_enum_func?
    |> parallelize_term()
  end

  defp which_enum_func?(ast) do
    {ast, SumMag.include_specified_functions?(ast, :Enum, env())}
  end

  def call_nif({:ok, asm}, :map) do
    %{
      operators: operators,
      args: args
    } = asm

    func_name = Optimizer.AFunction.generate_function_name(:map, asm)

    case Db.validate(func_name) do
      nil ->
        # plan to fix this data
        info = %{
          module: :enum,
          function: :map,
          nif_name: func_name,
          arg_num: 1,
          args: args,
          operators: operators
        }

        Db.register(info)

      # plan to fix this data
      true ->
        info = %{
          module: :enum,
          function: :map,
          nif_name: func_name,
          arg_num: 1,
          args: args,
          operators: operators
        }

        Db.register(info)

      false ->
        nil
    end

    func_name = func_name |> String.to_atom()

    quote do: ReplaceModule.unquote(func_name)
  end

  def call_nif({:error, asm}, _atom) do
    asm
  end
end
