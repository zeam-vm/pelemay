# defmodule VecSample do
# 	@moduledoc """
# 	Documentation for VecSample.
# 	"""

# 	@on_load :load_nifs

# 	def load_nifs do
# 		:erlang.load_nif('./priv/libnifvec', 0)
# 	end

# 	def func(_list), do: raise "NIF func/1 is not implemented"

# 	# def func_g(_list), do: raise "NIF func/1 is not implemented"

# 	def range_to_list(_range), do: raise "NIF range_to_list/1 is not implemented"

# 	def enum_map_mult_2(_list), do: raise "NIF enum_map_mult_2/1 is not implemented"

# 	def number_list_to_double_list(_list), do: raise "NIF number_list_to_double_list/1 is not implemented"

# 	def enum_map_logistic_map(_list, _p, _mu), do: raise "NIF enum_map_logistic_map/3 is not implemented"

# 	def enum_map_logistic_map_g(list, p, mu) do
# 		list
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 		|> Enum.map(& rem(mu * &1 * (&1 + 1), p))
# 	end

# 	def chunk_every(_list, _count), do: raise "NIF chunk_every/2 is not implemented"
# end
