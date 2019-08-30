# defmodule VecBench do
# 	use Benchfella

#   @default_prime 6_700_417
#   @default_mu 22
#   @default_loop 10

# 	@list_0x100  		VecSample.range_to_list(1..0x100)
# 	@list_0x1000 		VecSample.range_to_list(1..0x1000)
# 	@list_0x10000 	VecSample.range_to_list(1..0x10000)
# 	@list_0x100000	VecSample.range_to_list(1..0x100000)
# 	@list_0x200000	VecSample.range_to_list(1..0x200000)
# 	@chunk_list	VecSample.chunk_every(@list_0x100, 4)


# 	# bench "range_to_list 0x100" do
# 	# 	VecSample.range_to_list(1..0x100)
# 	# end

# 	# bench "Enum.to_list 0x100" do
# 	# 	Enum.to_list(1..0x100)
# 	# end

# 	# bench "range_to_list 0x1000" do
# 	# 	VecSample.range_to_list(1..0x1000)
# 	# end

# 	# bench "Enum.to_list 0x1000" do
# 	# 	Enum.to_list(1..0x1000)
# 	# end

# 	# bench "range_to_list 0x10000" do
# 	# 	VecSample.range_to_list(1..0x10000)
# 	# end

# 	# bench "Enum.to_list 0x10000" do
# 	# 	Enum.to_list(1..0x10000)
# 	# end

# 	# bench "range_to_list 0x100000" do
# 	# 	VecSample.range_to_list(1..0x100000)
# 	# end

# 	# bench "Enum.to_list 0x100000" do
# 	# 	Enum.to_list(1..0x100000)
# 	# end

# 	# bench "func 0x100" do
# 	# 	VecSample.func(@list_0x100)
# 	# end

# 	# bench "func 0x1000" do
# 	# 	VecSample.func(@list_0x1000)
# 	# end

# 	# bench "func 0x10000" do
# 	# 	VecSample.func(@list_0x10000)
# 	# end

# 	# bench "func 0x100000" do
# 	# 	VecSample.func(@list_0x100000)
# 	# end

# 	# bench "func 0x200000" do
# 	# 	VecSample.func(@list_0x200000)
# 	# end

# 	# bench "func_g 0x100" do
# 	# 	VecSample.func_g(@list_0x100)
# 	# end

# 	# bench "func_g 0x1000" do
# 	# 	VecSample.func_g(@list_0x1000)
# 	# end

# 	# bench "func_g 0x10000" do
# 	# 	VecSample.func_g(@list_0x10000)
# 	# end

# 	# bench "func_g 0x100000" do
# 	# 	VecSample.func_g(@list_0x100000)
# 	# end

# 	# bench "Enum.map 0x100" do
# 	# 	Enum.map(@list_0x100, & &1 * 2)
# 	# end

# 	# bench "enum_map_mult_2 0x100" do
# 	# 	VecSample.enum_map_mult_2(@list_0x100)
# 	# end

# 	# bench "Enum.map 0x1000" do
# 	# 	Enum.map(@list_0x1000, & &1 * 2)
# 	# end

# 	# bench "enum_map_mult_2 0x1000" do
# 	# 	VecSample.enum_map_mult_2(@list_0x1000)
# 	# end

# 	# bench "Enum.map 0x10000" do
# 	# 	Enum.map(@list_0x10000, & &1 * 2)
# 	# end

# 	# bench "enum_map_mult_2 0x10000" do
# 	# 	VecSample.enum_map_mult_2(@list_0x10000)
# 	# end

# 	#bench "Enum.map logistic_map 0x100" do
# 		# Enum.map(@list_0x100, & Enum.reduce(1..10, &1, fn _x, acc -> rem(@default_mu * acc * (acc + 1), @default_prime) end))
# 		# Enum.map(@list_0x100, & rem(@default_mu * &1 * (&1 + 1), @default_prime))
# 	#	VecSample.enum_map_logistic_map_g(@list_0x100, @default_prime, @default_mu)
# 	#end

# 	#bench "enum_map_logistic_map 0x100" do
# 	#	VecSample.enum_map_logistic_map(@list_0x100, @default_prime, @default_mu)
# 	#end

# 	#bench "Enum.chunk_every 0x100" do
# 	#	Enum.chunk_every(@list_0x100, 4)
# 	#end

# 	#bench "VecSample.chunk_every 0x100" do
# 	#	VecSample.chunk_every(@list_0x100, 4)
# 	#end

# 	#bench "List.flatten 0x100" do
# 	#	List.flatten(@chunk_list)
# 	#end
# end