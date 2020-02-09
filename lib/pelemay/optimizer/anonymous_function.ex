defmodule Optimizer.AFunction do
  def generate_function_name(func, %{args: args, operators: operators})
      when is_atom(func) do
    fun = fn
      {:&, _meta, [num]} -> "elem#{num}"
      {var, _, nil} -> Atom.to_string(var)
      other -> "#{other}"
    end

    [h | args] = Enum.map(args, &fun.(&1))

    expr =
      operators
      |> Enum.map(&Analyzer.operator_to_string(&1))
      |> Enum.zip(args)

    ret =
      expr
      |> Enum.reduce(h, fn {op, arg}, acc -> acc <> "_#{op}_#{arg}" end)

    func_name = Atom.to_string(func) <> "_"

    func_name <> ret
  end
end
