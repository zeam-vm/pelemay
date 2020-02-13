defmodule Optimizer do
  @moduledoc """
    Provides a optimizer for [AST](https://elixirschool.com/en/lessons/advanced/metaprogramming/)
  """
  import SumMag
  alias Pelemay.Db

  require Logger

  @term_options [Enum: true, String: true]

  @doc """
  Optimize funcions which be enclosed `defpelemay`, using `optimize_***` function.
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
    |> consist_alias(caller)
  end

  def consist_alias(definitions, module) do
    Macro.prewalk(
      definitions,
      fn
        {:__aliases__, [alias: false], [:ReplaceModule]} -> module
        other -> other
      end
    )
  end

  def consist_context(definitions) do
    Macro.prewalk(
      definitions,
      fn
        {
          ast,
          {{:., _, [_, func_name]}, [], _arg} = replacer
        } ->
          case Db.impl_validate(func_name) do
            true -> replacer
            _ -> ast
          end

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

  def parallelize_term({atom, _, nil} = arg, _)
      when is_atom(atom) do
    arg
  end

  def parallelize_term({atom, [], _} = arg, _)
      when is_atom(atom) do
    arg
  end

  def parallelize_term(term, {:Enum, true}) do
    info = SumMag.include_specified_functions?(term, :Enum, Enum.__info__(:functions))
    init(term, Enum: info)
  end

  def parallelize_term(term, {:String, true}) do
    info = SumMag.include_specified_functions?(term, :String, String.__info__(:functions))

    init(term, String: info)
  end

  def parallelize_term(term, _), do: term

  # @spec init(Macro.t(), list) :: 
  def init(ast, [{_, []}]), do: ast

  def init(ast, module_info) do
    {_func, _meta, args} = ast
    optimized_ast = parallelize(module_info, args)

    case optimized_ast do
      {:ok, opt_ast} -> {ast, opt_ast}
      {:error, _} -> ast
    end
  end

  defp parallelize(module_info, args) do
    Analyzer.supported?(args)
    |> verify
    |> case do
      {:ok, polymap} -> {:ok, call_nif(polymap, module_info)}
      {:error, _} -> {:error, "Not supported"}
    end
  end

  defp call_nif(polymap, module_info) do
    [{module, [{key, num}]}] = module_info

    func_name = Optimizer.AFunction.generate_function_name(key, polymap)

    case Db.validate(func_name) do
      false ->
        nil

      _ ->
        info = %{
          module: module,
          function: key,
          nif_name: func_name,
          arg_num: 1,
          args: polymap,
          impl: nil
        }

        Db.register(info)
    end

    replcae_function(func_name, polymap)
  end

  def replcae_function(func_name, polymap) do
    func_name = func_name |> String.to_atom()

    flat_vars =
      polymap
      |> Keyword.get_values(:var)
      |> List.flatten()

    {
      {:., [], [{:__aliases__, [alias: false], [:ReplaceModule]}, func_name]},
      [],
      flat_vars
    }
  end

  defp verify(polymap) when is_list(polymap) do
    var_num =
      polymap
      |> Keyword.get_values(:var)
      |> length

    func_num =
      polymap
      |> Keyword.get_values(:func)
      |> length

    case {var_num, func_num} do
      {0, 1} -> {:ok, polymap}
      {0, 0} -> {:error, polymap}
      {_, 0} -> {:ok, polymap}
    end
  end
end
