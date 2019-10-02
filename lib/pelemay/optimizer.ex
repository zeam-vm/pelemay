defmodule Optimizer do
  @moduledoc """
    Provides a optimizer for [AST](https://elixirschool.com/en/lessons/advanced/metaprogramming/)
  """
  def replace_expr(expr, options)
      when is_list(options) do
    Enum.reduce(
      options,
      expr,
      fn opt, acc -> replace_expr(acc, opt) end
    )
  end

  def replace_expr(expr, option)
      when is_atom(option) do
    case option do
      :enum -> Optimizer.Enum.replace_expr(expr)
      _ -> expr
    end
  end
end
