defmodule Hastega.Util do
  @moduledoc """
  Documentation for Hastega.Util.
  """

  @doc """
  wrap_do_clauses(do_clauses) returns do_clauses if do_clause is a list, otherwise wraps by a list.

    ## Examples

    iex> Hastega.Util.wrap_do_clauses([1, 2])
    [1, 2]
    iex> Hastega.Util.wrap_do_clauses(1)
    [1]

  """
  def wrap_do_clauses(do_clauses) when is_list(do_clauses), do: do_clauses
  def wrap_do_clauses(do_clause) when not is_list(do_clause), do: [do_clause]
end