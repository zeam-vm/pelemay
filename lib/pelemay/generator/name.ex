defmodule Generator.Name do
  import Util
  require Util

  def generate_function_name(func, polymap)
      when is_atom(func) and is_list(polymap) do
    ret =
      polymap
      |> Enum.reduce("", fn {_, x}, acc ->
        acc <> "_" <> generate_function_name(x)
      end)

    Atom.to_string(func) <> ret
  end

  def generate_function_name(functions, polymap)
      when is_list(functions) do
    debug(functions)
    debug(polymap)

    prefix =
      functions
      |> Enum.reduce("", fn [{func, _}], acc -> acc <> Atom.to_string(func) <> "_" end)

    postfix =
      polymap
      |> Enum.reduce("", fn x, acc ->
        acc <> "_" <> generate_function_name(x)
      end)

    debug(prefix)
    debug(postfix)

    prefix <> postfix
  end

  def generate_function_name({:&, _meta, [num]}) do
    "elem#{num}"
  end

  def generate_function_name({var, _, nil}) do
    Atom.to_string(var)
  end

  def generate_function_name({:@, _, [{var, _, nil}]}) do
    Atom.to_string(var) |> String.upcase()
  end

  def generate_function_name(%{args: args, operators: operators}) do
    [h | string_args] = Enum.map(args, &generate_function_name(&1))

    operators
    |> Enum.map(&operator_to_string(&1))
    |> Enum.zip(string_args)
    |> Enum.reduce(h, fn {op, arg}, acc -> acc <> "_#{op}_#{arg}" end)
  end

  def generate_function_name({:func, polymap}) do
    generate_function_name(polymap)
  end

  def generate_function_name(other), do: "#{other}"

  def operator_to_string(func) when is_bitstring(func), do: func

  def operator_to_string(operator)
      when operator |> is_atom do
    case operator do
      :* -> "mult"
      :+ -> "plus"
      :- -> "minus"
      :/ -> "div"
      :rem -> "mod"
      _ -> "logic"
    end
  end
end
