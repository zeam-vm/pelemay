defmodule Pelemay do
  import SumMag
  # import Pelemay.Db
  # import Pelemay.Generator
  import SumMag

  alias Pelemay.Generator
  alias Pelemay.Db
  alias Pelemay.Func

  @moduledoc """
  ## Pelemay: Hyper Accelerator of Spreading Tasks for Elixir with GPU Activation

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

      pelemaystub
    end
  ```
  """
  defmacro defpelemay(functions) do
    Db.init

    functions
    |> SumMag.map(& accelerate(&1))
    |> pelemaystub
  end

  def pelemaystub(ret) do
    Generator.generate
    ret
  end

  @doc """
        iex> 
  """
  def accelerate(exprs) when is_list(exprs) do
    exprs

    # This is proto-type
    # |> fusion_function
    |> Enum.map(& replace_expr(&1) )
  end

  @doc """
        iex> 
  """
  defp replace_expr({{atom, _, nil}, _pos} = arg) 
    when atom |> is_atom do
     arg
  end

  defp replace_expr({quoted, pos}) do
    ret = quoted
    |> Pelemay.Enum.replace_expr

    {ret, pos}
  end

end

defmodule Pelemay.Enum do
  alias Pelemay.Db
  alias Pelemay.Func

  def replace_expr({quoted, :map}) do
    # include ast of Enum.map
    {_enum_map, _, anonymous_func} = quoted

    anonymous_func
    |> Func.supported?
    |> call_nif(:map)
  end

  def replace_expr({quoted, :chunk_every}) do
    IO.puts "Find Enum.chunk_every"
    {_enum, _, num} = quoted
    
    call_nif(num, :chunk_every)
  end

  def replace_expr({quoted, _func}) do
    str = Macro.to_string(quoted)

    IO.puts "Sorry, #{str} not supported yet."
    quoted
  end

  def replace_expr(other) do
    other
    |> which_enum_func?
    |> replace_expr
  end

  defp which_enum_func?(ast) do
    {_, flag} = Macro.prewalk(ast, false,
      fn 
      ({:__aliases__, _,[:Enum]} = ast, _) -> {ast, true}
      (other, acc) -> {other, acc}
      end)

    case flag do
      true -> {ast, ast |> which_function?}
      false -> {ast, nil}
    end
  end

  defp which_function?(ast) do
    {_, func} = Macro.prewalk(ast, false,
      fn 
      (:map = ast, _acc) -> {ast, :map}
      (:chunk_every = ast, _acc) ->{ast, :chunk_every}
      (other, acc) -> {other, acc}
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
      (# plan to fix this data
        info = %{
          module: :enum,
          function: :map,
          nif_name: func_name,
          arg_num: 1,
          args: args, 
          operators: operators
        }

        Db.register(info))
      true -> (# plan to fix this data
        info = %{
          module: :enum,
          function: :map,
          nif_name: func_name,
          arg_num: 1,
          args: args, 
          operators: operators
        }

        Db.register(info))
      false -> nil
    end

    func_name = func_name |> String.to_atom

    quote do: PelemayNif.unquote(func_name)
  end

  def call_nif({:error, asm}, _atom) do
    asm
  end

  defp generate_function_name(func, operators) do
    ret = operators
    |> Enum.map(& &1 |> operator_to_string)
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



defmodule Pelemay.Func do
  import SumMag

  defmodule Env do
    defstruct operator: [:+, :-, :*, :/, :rem]
  end

  def supported?([{:&, _, [1]}] = ast) do
    {:value, ast}
  end

  # Anonymous functions by fn
  def supported?( [{:fn, _, [{:->, _, [_arg, expr]}]}] ) do
    supported_expr?(expr)
  end

  # Anonymous functions by &
  def supported?([{:&, _, other}]) do
    other |> hd |> supported_expr?
  end

  defp supported_expr?({_atom, _, [_left, _right]} = ast) do
    expr_map = ast |> polynomial

    if supported_operators?(expr_map) do
      {:ok, expr_map}
    else
      {:error, ast}
    end
  end

  def polynomial(ast) do
    acc = %{ 
      operators: [],
      args: []
    }

    Macro.prewalk(ast, acc, &numerical?/2) |> elem(1)
  end

  defp numerical?({atom, _, [left, right]} = ast, acc) do
    %{ 
      operators: operators,
      args: args
    } = acc

    %Pelemay.Func.Env{}.operator
    |> Enum.find_value(fn x -> x == atom end)

    operators = case atom do
      :+ ->   [:+  | operators]
      :- ->   [:-  | operators]
      :* ->   [:*  | operators]
      :/ ->   [:/  | operators]
      :rem -> [:rem  | operators]
      _ ->    operators
    end

    args = args
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

  def supported_polinomial?(ast) do
    ast
    |> polynomial
    |> supported_operators?
  end

  def supported_operators?(%{operators: operators, args: args}) do
    if length(operators) != (length(args)-1) do
      false
    else
      true
    end
  end
end