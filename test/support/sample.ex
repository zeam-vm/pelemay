defmodule Sample do
  import Pelemay
  require Pelemay

  defpelemay do
    def list_square(list) when is_list(list) do
      list
      |> Enum.map(&(&1 * &1))
    end

    def list_plus1(list) do
      list
      |> Enum.map(&(&1 + 1))
    end

    def list_plus1_mult2(list) do
      list
      |> Enum.map(&(&1 + 1))
      |> Enum.map(&(&1 * 2))
    end

    def list_chunk_by(list, num) do
      list
      |> Enum.chunk_by(num)
    end

    def list_chunk_every(list, num) do
      list
      |> Enum.chunk_every(num)
    end

    def list_reduce_sum(list) do
      list
      |> Enum.reduce(0, fn x, acc -> x + acc end)
    end

    def list_mult_sort(list) do
      list
      |> Enum.map(&(&1 * 2))
      |> Enum.sort()
    end 

    def list_zip(a, b) do
      Enum.zip(a, b)
    end
  end
end
