defmodule Optimizer do
  @moduledoc """
    Provides a optimizer for [AST](https://elixirschool.com/en/lessons/advanced/metaprogramming/)
  """
  import SumMag
  alias Pelemay.Db

  @term_options [enum: true]
  # @macro_patterna {{:., [], [{:__aliases__, [alias: false], [:ReplaceModule]}, :logistic_map]},[],[]}
  # @macro_pattern_arg {:list, [], Elixir}
  # @macro_pattern_b {:|>, [], [@macro_pattern_arg, @macro_patterna]}

  @doc """
  Optimize funcions which be enclosed `defptermay`, using `optimize_***` function.
  Input is funcion definitions.
  ```
  quote do
    def twice_plus(list) do
      twice = list |> Enum.map(&(&1*2))
      twice |> Enum.map(&(&1+1))
    end 

    def foo, do: "foo"
  end
  ```
  """
  def replace(definitions, caller) do
    definitions
    |> melt_block
    |> Enum.map(&optimize_func(&1))
    |> iced_block
    |> consist_context(caller)
  end

  def consist_context(funcs, module) do
    Macro.prewalk(
      funcs,
      fn
        {:__aliases__, [alias: false], [:ReplaceModule]} -> module
        other -> other
      end
    )
  end

  def map_fold(funcs, value, arg_info) do
    macro_pattern_a =
      {{:., [], [{:__aliases__, [alias: false], [:ReplaceModule]}, arg_info]}, [], []}

    macro_pattern_arg = value
    macro_pattern_b = {:|>, [], [macro_pattern_arg, macro_pattern_a]}

    Macro.postwalk(
      funcs,
      fn
        {:|>, [], [macro_pattern_b, macro_pattern_a]} ->
          {:|>, [], [macro_pattern_arg, macro_pattern_a]}

        other ->
          other
      end
    )
  end

  @doc """
  Input is one funcion definition:
  ```
  quote do
    def twice_plus(list) do
      twice = list |> Enum.map(&(&1*2))
      twice |> Enum.map(&(&1+1))
    end 
  end
  ```
  """
  def optimize_func({def_key, meta, [arg_info, exprs]} = ast) do
    func =
      case def_key do
        :def -> {:def, meta, [regist_arg_info(arg_info), optimize_exprs(exprs)]}
        :defp -> {:defp, meta, [arg_info, optimize_exprs(exprs)]}
        _ -> raise ArgumentError, message: Macro.to_string(ast)
      end

    value = get_value(arg_info)
    map_fold(func, value, arg_info)
  end

  def regist_arg_info({def_name, _, _} = arg_info) do
    Db.regist_arg_info(def_name)
    arg_info
  end

  def get_value({_, _, value_info}) do
    [value] = value_info
    value
  end

  @doc """
  Input is some expresions:
  ```
  quote do
    twice = list |> Enum.map(&(&1*2))
    twice |> Enum.map(&(&1+1))
  end
  ```
  """
  def optimize_exprs(exprs) do
    exprs
    |> melt_block
    |> Enum.map(&optimize_expr(&1))
    |> iced_block
  end

  @doc """
  Input is one expression:
  ```
  quote do
    twice = list |> Enum.map(&(&1*2))
  end
  ```
  """
  def optimize_expr(expr) do
    expr
    |> Macro.unpipe()
    |> accelerate_expr()
    |> pipe
  end

  defp accelerate_expr(unpiped_list) do
    # Delete pos
    expr = Enum.map(unpiped_list, fn {x, _} -> x end)

    optimized_expr = Enum.map(expr, &parallelize_term(&1, @term_options))

    # Add pos
    Enum.map(optimized_expr, fn x -> {x, 0} end)
  end

  @doc """
  Input is a term:
  ```
  quote do: list
  quote do: list
  quote do: Enum.map(&(&1*2))
  ```
  """
  def parallelize_term(term, options)
      when is_list(options) do
    Enum.reduce(
      options,
      term,
      fn opt, acc -> parallelize_term(acc, opt) end
    )
  end

  def parallelize_term(term, {:enum, true}), do: Optimizer.Enum.parallelize_term(term)
  def parallelize_term(term, _), do: term
end
