defmodule Hnum.Tuple do
	def tuple_test(tuple, func) do
		acc = func.( tuple |> elem(0) )
		tuple_test(tuple, func, 1, [acc])	
	end

	def tuple_test(tuple, func, index, acc) do
		size = tuple |> tuple_size
		if index == size do
			acc
		else
			acc = [acc | func.( tuple |> elem(index) ) ]
			tuple_test(tuple, func, index+1, acc)
		end
	end

	def tuple_test1(tuple, func) do
		acc = func.( tuple |> elem(0) )
		tuple_test1(tuple, func, 1, [acc])	
	end

	def tuple_test1(tuple, func, index, acc) do
		size = tuple |> tuple_size
		if index == size do
			acc |> Enum.reverse
		else
			tmp = [ func.( tuple |> elem(index) ) ]
			acc = tmp ++ acc
			tuple_test1(tuple, func, index+1, acc)
		end
	end

	def map(tuple, func) do
		size = tuple |> tuple_size
		for i <- 0..(size-1) do
			func.( tuple |> elem( i ) )
		end
	end
end