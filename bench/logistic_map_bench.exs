defmodule LogisticMapBench do
  use Benchfella

  @range_0x100    (1..0x100)
  @range_0x1000   (1..0x1000)
  @range_0x10000  (1..0x10000)
  @list_0x100     (1..0x100) |> Enum.to_list
  @list_0x1000    (1..0x1000) |> Enum.to_list
  @list_0x10000   (1..0x10000) |> Enum.to_list
  @list_0x100000  (1..0x100000) |> Enum.to_list

  bench "Pure" do
    @list_0x100
    |> Sample.pure_logistic_map
  end

  bench "Accelerated" do
    @list_0x100
    |> Sample.logistic_map
  end
end