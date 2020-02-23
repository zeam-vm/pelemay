defmodule Analyzer do
  import SumMag

  @moduledoc """
  Provides optimizer for anonymous functions.
  """

  @doc """
  iex> var = quote do [x] end 
  iex> Analyzer.parse(var)
  [var: {:x, [], AnalyzerTest}]
  """
  def parse(args) when is_list(args) do
    func = fn node, asm ->
      [supported?(node) | asm]
    end

    args
    |> Enum.reduce([], func)
    |> Enum.reverse()
    |> List.flatten()
  end

  def parse(other), do: [var: other]

  @doc """
  Check if expressions can be optimzed.

  When the expression is enable to optimize, {:ok, map} is returned.
  The map is shape following: %{args: _, operators: _}.

  iex> var = quote do x end
  ...> Analyzer.supported?(var)
  [var: {:x, [], AnalyzerTest}]

  iex> quote do
  ...>   fn x -> x + 1 end
  ...> end |> Analyzer.supported?
  [func: %{args: [{:x, [], AnalyzerTest}, 1], operators: [:+]}]
  """
  def supported?({_, _, atom} = var) when is_atom(atom) do
    [var: var]
  end

  def supported?({:@, _, [{_, _, nil}]} = var) do
    [var: var]
  end

  def supported?({:fn, _, [{:->, _, [_arg, expr]}]}) do
    polynomial_map(expr)
  end

  def supported?({:&, _, expr}) do
    expr |> hd |> polynomial_map
  end

  def supported?(num) when is_number(num) do
    [var: [num]]
  end

  def supported?(other) do
    other
    |> Macro.quoted_literal?()
    |> case do
      false -> {:error, other}
      true -> [var: other]
    end
  end

  def polynomial_map(ast) do
    acc = %{
      operators: [],
      args: []
    }

    polymap = Macro.prewalk(ast, acc, &numerical?/2) |> elem(1)
    [func: polymap]
  end

  defp numerical?({:., _, _} = aliases, acc), do: {aliases, acc}
  defp numerical?({:__aliases__, _, _} = aliases, acc), do: {aliases, acc}

  defp numerical?({:&, _, _} = cap_val, acc), do: {cap_val, acc}

  defp numerical?({_atom, _, context} = val, acc) when is_atom(context) do
    {val, acc}
  end

  defp numerical?({atom, _, args} = ast, acc) when is_list(args) do
    %{
      operators: operators,
      args: map_args
    } = acc

    operators =
      case operator(atom) do
        false -> operators
        atom -> [atom | operators]
      end

    map_args =
      args
      |> Enum.reverse()
      |> Enum.reduce(
        map_args,
        fn x, acc ->
          listing_literal(x, acc)
        end
      )

    ret = %{
      operators: operators,
      args: map_args
    }

    {ast, ret}
  end

  defp numerical?(other, acc), do: {other, acc}

  def listing_literal(term, acc) do
    if Macro.quoted_literal?(term) do
      [term | acc]
    else
      case quoted_var?(term) do
        false -> acc
        _ -> [term | acc]
      end
    end
  end

  defp operator(:+), do: :+
  defp operator(:-), do: :-
  defp operator(:/), do: :/
  defp operator(:*), do: :*
  defp operator(:rem), do: :rem

  # Logical Operator
  defp operator(:>=), do: :>=
  defp operator(:<=), do: :<=
  defp operator(:!=), do: :!=
  defp operator(:<), do: :<
  defp operator(:>), do: :>
  defp operator(:==), do: :==
  defp operator(:!), do: :!
  defp operator(:!==), do: :!==
  defp operator(:<>), do: :<>

  defp operator({:., _, [{:__aliases__, _, [module]}, func]}) do
    Atom.to_string(module) <> "." <> Atom.to_string(func)
  end

  defp operator(_), do: false
end
