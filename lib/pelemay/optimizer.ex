defmodule Optimizer do
  @moduledoc """
    Provides a optimizer for [AST](https://elixirschool.com/en/lessons/advanced/metaprogramming/)
  """
  import SumMag

  @term_options [enum: true]

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

  defp optimize_func({def_key, meta, [arg_info, exprs]}) do
    case def_key do
      :def -> {:def, meta, [arg_info, optimize_exprs(exprs)]}
      :defp -> {:defp, meta, [arg_info, optimize_exprs(exprs)]}
      _ -> raise ArgumentError
    end
  end

  defp optimize_exprs(exprs) do
    exprs
    |> melt_block
    |> Enum.map(&optimize_expr(&1))
    |> iced_block
  end

  defp optimize_expr(expr) do
    expr
    |> Macro.unpipe()
    |> accelerate_expr()
    |> pipe
  end

  def accelerate_expr(unpiped_list) do
    # Delete pos
    expr = Enum.map(unpiped_list, fn {x, _} -> x end)

    expr
    |> Enum.map(&accelerate_elem(&1, @term_options))

    # Add pos
    Enum.map(expr, fn x -> {x, 0} end)
  end

  def accelerate_elem(elem, options)
      when is_list(options) do
    Enum.reduce(
      options,
      elem,
      fn opt, acc -> accelerate_elem(acc, opt) end
    )
  end

  def accelerate_elem(elem, {:enum, true}), do: Optimizer.Enum.replace_term(elem)
  def accelerate_elem(elem, _), do: elem
end
