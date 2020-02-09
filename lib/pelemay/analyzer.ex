defmodule Analyzer do
  import SumMag

  @type asm :: %{args: list(any), operators: list(atom)}

  @moduledoc """
  Provides optimizer for anonymous functions.
  """

  @doc """
  Check if expressions can be optimzed.

  When the expression is enable to optimize, {:ok, map} is returned.
  The map is shape following: %{args: _, operators: _}.

  iex> var = quote do x end
  ...> Analyzer.supported?(var)
  {:error, {:x, [], AnalyzerTest}}

  iex> var = quote do [x] end 
  iex> Analyzer.supported?(var)
  {:ok, %{args: [{:x, [], AnalyzerTest}], operators: []}}

  iex> quote do
  ...>   fn x -> x + 1 end
  ...> end |> Analyzer.supported?
  {:ok, %{args: [{:x, [], AnalyzerTest}, 1], operators: [:+]}}
  """
  @spec supported?(Macro.t()) :: asm
  def supported?([{val, line, atom}]) when is_atom(atom) do
    asm = %{
      operators: [],
      args: [{val, line, atom}]
    }

    {:ok, asm}
  end

  def supported?([{:fn, _, [{:->, _, [_arg, expr]}]}]) do
    supported_expr?(expr)
  end

  def supported?({:fn, _, [{:->, _, [_arg, expr]}]}) do
    supported_expr?(expr)
  end

  # Anonymous functions by &
  def supported?([{:&, _, other}]) do
    other |> hd |> supported_expr?
  end

  def supported?({:&, _, other}) do
    other |> hd |> supported_expr?
  end

  def supported?(other), do: {:error, other}

  defp supported_expr?({_atom, _, [_left, _right]} = ast) do
    expr_map = ast |> polynomial_map

    if verify(expr_map) do
      {:ok, expr_map}
    else
      {:error, ast}
    end
  end

  def polynomial_map(ast) do
    acc = %{
      operators: [],
      args: []
    }

    Macro.prewalk(ast, acc, &numerical?/2) |> elem(1)
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
  defp operator(:!=), do: :!=
  defp operator(:!==), do: :!==
  defp operator(:<>), do: :<>

  defp operator(_), do: false

  def operator_to_string(operator)
      when operator |> is_atom do
    case operator do
      :* -> "mult"
      :+ -> "plus"
      :- -> "minus"
      :/ -> "div"
      :rem -> "mod"
      other -> "logic"
    end
  end

  defp numerical?({atom, _, [left, right]} = ast, acc) do
    %{
      operators: operators,
      args: args
    } = acc

    operators =
      case operator(atom) do
        false -> operators
        atom -> [atom | operators]
      end

    args =
      args
      |> listing_literal(right)
      |> listing_literal(left)

    ret = %{
      operators: operators,
      args: args
    }

    {ast, ret}
  end

  defp numerical?(other, acc), do: {other, acc}

  defp listing_literal(acc, term) do
    if Macro.quoted_literal?(term) do
      [term | acc]
    else
      case quoted_var?(term) do
        false -> acc
        _ -> [term | acc]
      end
    end
  end

  defp verify(%{operators: operators, args: args}) do
    if length(operators) != length(args) - 1 do
      false
    else
      true
    end
  end
end
