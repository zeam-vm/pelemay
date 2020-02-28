defmodule Generator.Name do
  @doc """
  iex> func_label = [[map: 1]]
  iex> polymap = [func: %{args: [{:&, [], [1]}, {:&, [], [1]}], operators: [:*]}]
  iex> Generator.Name.generate_function_name(func_label, polymap)
  "map_elem1_mult_elem1"
  """
  def generate_function_name(functions, polymap)
      when is_list(functions) do
    {_, prefix} =
      functions
      |> Enum.reduce("", fn [{func, _}], acc -> acc <> "_" <> Atom.to_string(func) end)
      |> String.split_at(1)

    postfix =
      polymap
      # |> IO.inspect(label: "polymap")
      |> Enum.reduce("", fn x, acc ->
        acc <> "_" <> arg_to_string(x)
      end)

    prefix <> postfix
  end

  def arg_to_string({:&, _meta, [num]}) do
    "elem#{num}"
  end

  def arg_to_string({var, _, context})
      when is_atom(context) and is_atom(context) do
    Atom.to_string(var)
  end

  def arg_to_string({:@, _, [{var, _, nil}]}) do
    Atom.to_string(var) |> String.upcase()
  end

  def arg_to_string(%{args: args, operators: operators}) do
    [h | string_args] = Enum.map(args, &arg_to_string(&1))

    operators
    |> Enum.map(&operator_to_string(&1))
    |> Enum.zip(string_args)
    |> Enum.reduce(h, fn {op, arg}, acc -> acc <> "_#{op}_#{arg}" end)
  end

  def arg_to_string({:func, polymap}) do
    arg_to_string(polymap)
  end

  def arg_to_string({:var, polymap}) do
    arg_to_string(polymap)
  end

  def arg_to_string(other), do: "#{other}"

  def operator_to_string(func) when is_bitstring(func), do: ""

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
