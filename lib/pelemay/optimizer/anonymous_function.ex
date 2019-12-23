defmodule Optimizer.AFunction do
  def generate_function_name(func, %{args: args, operators: operators})
      when is_atom(func) do
    fun = fn
      {:&, _meta, [1]} -> "elem"
      {var, _, nil} -> Atom.to_string(var)
      other -> "#{other}"
    end

    [h | args] = Enum.map(args, &fun.(&1))

    expr =
      operators
      |> Enum.map(&operator_to_string(&1))
      |> Enum.zip(args)

    ret =
      expr
      |> Enum.reduce(h, fn {op, arg}, acc -> acc <> "_#{op}_#{arg}" end)

    func_name = Atom.to_string(func) <> "_"

    func_name <> ret
  end

  def operator_to_string(operator)
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
