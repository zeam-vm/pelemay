defmodule Optimizer.AFunction do
  def generate_function_name(func, polymap)
      when is_list(polymap) do
    ret =
      polymap
      |> Enum.reduce("", fn {_, x}, acc -> acc <> "_" <> generate_function_name(x) end)

    Atom.to_string(func) <> ret
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
    |> Enum.map(&Analyzer.operator_to_string(&1))
    |> Enum.zip(string_args)
    |> Enum.reduce(h, fn {op, arg}, acc -> acc <> "_#{op}_#{arg}" end)
  end

  def generate_function_name(other), do: "#{other}"
end
