defmodule Pelemay do
  import SumMag

  alias Pelemay.Generator
  alias Pelemay.Db

  @moduledoc """
  ## Pelemay: The Penta (Five) “Elemental Way”: Freedom, Insight, Beauty, Efficiency and Robustness

  For example, the following code of the function `map_square` will be compiled to native code using SIMD instructions by Pelemay.

  ```elixir
  defmodule M do
    require Pelemay
    import Pelemay

    defpelemay do
      def map_square (list) do
        list
        |> Enum.map(& &1 * &1)
      end
    end
  ```

  1. Find Enum.map with a specific macro
  2. Analyze internal anonymous functions
  3. Register(ETS) following information as Map.
    - Module
    - Original function name
    - Function name for NIF
    - Value of Anonymous Function
  4. Insert NIF in AST
  5. Do Step 1 ~ 4 to each macro
  6. Receiving Map from ETS, and...
  7. Generate NIF Code
  8. Generate Elixir's functions
  9. Compile NIF as Custom Mix Task, using Clang
  """
  defmacro defpelemay(functions) do
    Db.init()

    caller_name = __CALLER__.module |> Generator.elixir_nif_module() |> String.to_atom()

    functions
    |> SumMag.replace()
    |> consist_context(caller_name)
    |> pelemaystub(__CALLER__.module)
  end

  defp pelemaystub(ret, module) do
    Generator.generate(module)
    ret
  end

  defp consist_context(funcs, module) do
    Macro.prewalk(
      funcs,
      fn
        {:__aliases__, [alias: false], [:ReplaceModule]} -> module
        other -> other
      end
    )
  end
end

defmodule Analyzer.AFunc do
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

    if supported_operators?(expr_map) do
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
  defp operator(_), do: false

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

  defp numerical?(other, acc) do
    {other, acc}
  end

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

  defp supported_operators?(%{operators: operators, args: args}) do
    if length(operators) != length(args) - 1 do
      false
    else
      true
    end
  end
end
