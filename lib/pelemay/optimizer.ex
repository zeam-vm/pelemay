defmodule Optimizer do
  @moduledoc """
    Provides a optimizer for [AST](https://elixirschool.com/en/lessons/advanced/metaprogramming/)
  """
  import SumMag

  @term_options [enum: true]

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

  defp consist_context(funcs, module) do
    Macro.prewalk(
      funcs,
      fn
        {:__aliases__, [alias: false], [:ReplaceModule]} -> module
        other -> other
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
    case def_key do
      :def -> {:def, meta, [arg_info, optimize_exprs(exprs)]}
      :defp -> {:defp, meta, [arg_info, optimize_exprs(exprs)]}
      _ -> raise ArgumentError, message: Macro.to_string(ast)
    end
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
