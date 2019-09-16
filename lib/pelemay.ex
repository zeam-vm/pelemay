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

    functions
    |> SumMag.map(&Optimizer.replace_expr(&1))
    |> pelemaystub
  end

  defp pelemaystub(ret) do
    Generator.generate()
    ret
  end
end

defmodule Optimizer do
  @moduledoc """
    Provides a optimizer for [AST](https://elixirschool.com/en/lessons/advanced/metaprogramming/)
  """
  def replace_expr({atom, _, nil} = arg)
      when atom |> is_atom do
    arg
  end

  def replace_expr(quoted) do
    quoted
    |> Optimizer.Enum.replace_expr()
  end
end

defmodule Optimizer.Enum do
  alias Pelemay.Db
  alias Analyzer.AFunc

  def replace_expr({quoted, :map}) do
    # include ast of Enum.map
    {_enum_map, _, anonymous_func} = quoted

    anonymous_func
    |> AFunc.supported?()
    |> call_nif(:map)
  end

  def replace_expr({quoted, :chunk_every}) do
    {_enum, _, num} = quoted

    call_nif(num, :chunk_every)
  end

  def replace_expr({quoted, _func}) do
    str = Macro.to_string(quoted)

    IO.puts("Sorry, #{str} not supported yet.")
    quoted
  end

  def replace_expr(other) do
    other
    |> which_enum_func?
    |> replace_expr
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
    quote do: PelemayNif.chunk_every(unquote(num))
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

    quote do: PelemayNif.unquote(func_name)
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
  @spec supported?( Macro.t() ) :: asm
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
