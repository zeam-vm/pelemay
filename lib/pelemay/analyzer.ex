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

  """
  @spec supported?(Macro.t()) :: asm
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

  # !/1   !=/2
  # !==/2 %/2
  # %{}/1 &&/2
  # &/1   */2
  # ++/2  +/1
  # +/2   --/2
  # -/1   -/2
  # ../2  ./2
  # //2   ::/2
  # </2   <<>>/1
  # <=/2  <>/2
  # =/2   ==/2
  # ===/2 =~/2
  # >/2   >=/2
  # @/1   ^/1

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
