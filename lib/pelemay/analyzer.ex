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

  def supported_isboolean?([{:fn, _, [{:->, _, [_arg, expr]}]}]) do
    isboolean_expr?(expr)
  end

  def supported_isboolean?({:fn, _, [{:->, _, [_arg, expr]}]}) do
  end

  def supported_isboolean?([{:&, _, other}]) do
  end

  def supported_isboolean?({:&, _, other}) do
  end

  defp operator(:==), do: {:==, :comp}
  defp operator(:>=), do: {:>=, :comp}
  defp operator(:<=), do: {:<=, :comp}
  defp operator(:>), do: {:>, :comp}
  defp operator(:<), do: {:<, :comp}

  #抽象構文木の初期頂点のオペランドからその式がbooleanを返すかを判定する。
  defp isboolean_expr?({atom, _, [left, right]} = ast) do
    cmp = 
    case operator(atom) do
      false -> {:error, ast}
      {atom, :comp} -> atom
    end
  end


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

  defp operator(:+), do: {:+, :arith}
  defp operator(:-), do: {:-, :arith}
  defp operator(:/), do: {:/, :arith}
  defp operator(:*), do: {:*, :arith}
  defp operator(:rem), do: {:rem, :arith}
  defp operator(_), do: false

  defp numerical?({atom, _, [left, right]} = ast, acc) do
    %{
      operators: operators,
      args: args
    } = acc

    operators =
      case operator(atom) do
        false -> operators
        {atom, :arith} -> [atom | operators]
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
