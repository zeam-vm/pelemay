defmodule Pelemay.Generator.Native.Util do
  alias Pelemay.Db

  def push_info(info, key, val) do
    Map.update(info, key, val, fn _ -> val end)
    |> Db.register()
  end

  def push_impl_info(info, exists_impl?, exists_driver?) do
    Map.update(info, :impl, exists_impl?, fn _ -> exists_impl? end)
    |> Map.update(:impl_drv, exists_driver?, fn _ -> exists_driver? end)
    |> Db.register()
  end

  def to_str_code(list) when list |> is_list do
    list
    |> Enum.reduce(
      "",
      fn x, acc -> acc <> to_string(x) end
    )
  end

  defp enclosure(str) do
    "(#{str})"
  end

  def make_expr(operators, args, type)
      when is_list(operators) and is_list(args) do
    args = args |> to_string(:args, type)

    operators = operators |> to_string(:op)

    last_arg = List.last(args)

    expr =
      Enum.zip(args, operators)
      |> Enum.reduce("", &make_expr/2)

    if type == "double" && String.contains?(expr, "%") do
      "(vec_double[i])"
    else
      enclosure(expr <> last_arg)
    end
  end

  def make_expr({arg, operator}, acc) do
    enclosure(acc <> arg) <> operator
  end

  defp to_string(args, :args, "double") do
    args
    |> Enum.map(&(&1 |> arg_to_string("double")))
  end

  defp to_string(args, :args, type) do
    args
    |> Enum.map(&(&1 |> arg_to_string(type)))
  end

  defp to_string(operators, :op) do
    operators
    |> Enum.map(&(&1 |> operator_to_string))
  end

  defp arg_to_string(arg, type) do
    case arg do
      {:&, _meta, [1]} -> "vec_#{type}[i]"
      {:&, _meta, [2]} -> "vec_#{type}[i + 1]"
      {_, _, nil} -> "vec_#{type}[i]"
      other -> "#{other}"
    end
  end

  defp operator_to_string(operator) do
    case operator do
      :rem -> "%"
      other -> other |> to_string
    end
  end
end
