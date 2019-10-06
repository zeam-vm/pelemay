defmodule Optimizer.Enum do
  import Analyzer
  alias Pelemay.Db

  def replace_term({atom, _, nil} = arg)
      when atom |> is_atom do
    arg
  end

  def replace_term({quoted, :map}) do
    # include ast of Enum.map
    {_enum_map, _, anonymous_func} = quoted

    anonymous_func
    |> supported?()
    |> call_nif(:map)
  end

  def replace_term({quoted, :chunk_every}) do
    {_enum, _, num} = quoted

    call_nif(num, :chunk_every)
  end

  def replace_term({quoted, _func}) do
    str = Macro.to_string(quoted)

    IO.puts("Sorry, #{str} not supported yet.")
    quoted
  end

  def replace_term(other) do
    other
    |> which_enum_func?
    |> replace_term()
  end

  defp which_enum_func?(ast) do
    {_, flag} =
      Macro.prewalk(ast, false, fn
        {:__aliases__, _, [:Enum]} = ast, _ -> {ast, true}
        other, acc -> {other, acc}
      end)

    case flag do
      true -> {ast, ast |> which_function?}
      false -> {ast, nil}
    end
  end

  defp which_function?(ast) do
    {_, func} =
      Macro.prewalk(ast, false, fn
        :map = ast, _acc -> {ast, :map}
        :chunk_every = ast, _acc -> {ast, :chunk_every}
        other, acc -> {other, acc}
      end)

    func
  end

  def call_nif(num, :chunk_every) do
    quote do: ReplaceModule.chunk_every(unquote(num))
  end

  def call_nif({:ok, asm}, :map) do
    %{
      operators: operators,
      args: args
    } = asm

    func_name = generate_function_name(:map, operators)

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

  defp generate_function_name(func, operators) do
    ret =
      operators
      |> Enum.map(&(&1 |> operator_to_string))
      |> Enum.reduce("", fn x, acc -> acc <> "_#{x}" end)

    Atom.to_string(func) <> ret
  end

  defp operator_to_string(operator)
       when operator |> is_atom do
    case operator do
      :* -> "mult"
      :+ -> "plus"
      :- -> "minus"
      :/ -> "div"
      :rem -> "mod"
    end
  end
end
