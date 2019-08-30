defmodule HastegaBench do
  use Benchfella

  @range_0x100    (1..0x100)
  @range_0x1000   (1..0x1000)
  @range_0x10000  (1..0x10000)
  @list_0x100     (1..0x100) |> Enum.to_list
  @list_0x1000    (1..0x1000) |> Enum.to_list
  @list_0x10000   (1..0x10000) |> Enum.to_list
  @list_0x100000  (1..0x100000) |> Enum.to_list

  @ncore :erlang.system_info :logical_processors
  # @md100 100/@ncore |> 

  # bench "Enum.map: 0x100 * 2" do
  #   Enum.map(@list_0x100, & &1 * 2)
  # end

  # bench "Enum.map: 0x1000 * 2" do
  #   Enum.map(@list_0x1000, & &1 * 2)
  # end

  # bench "Enum.map: 0x10000 * 2" do
  #   Enum.map(@list_0x10000, & &1 * 2)
  # end

  # bench "Flow.map: 0x100 * 2" do
  #   @list_0x100
  #   |> Flow.from_enumerable(max_demand: )
  #   |> Flow.map(& &1 * 2)
  #   # |> Flow.partition
  #   |> Enum.sort
  # end

  # bench "Flow.map: 0x1000 * 2" do
  #   @list_0x1000
  #   |> Flow.from_enumerable(max_demand: 1000/@ncore)
  #   |> Flow.map(& &1 * 2)
  #   # |> Flow.partition
  #   |> Enum.sort
  # end

  # bench "Flow.map: 0x10000 * 2" do
  #   @list_0x10000
  #   |> Flow.from_enumerable(max_demand: 10000/@ncore)
  #   |> Flow.map(& &1 * 2)
  #   |> Enum.sort
  # end

  # bench "Hastega Enum.map: 0x1000 * 2" do
  #   HastegaSample.list_mult_2(@list_0x1000)
  # end

  # bench "Hastega Enum.map: 0x100 * 2" do
  #   HastegaSample.list_mult_2(@list_0x100)
  # end

  # bench "Hastega Enum.map: 0x10000 * 2" do
  #   HastegaSample.list_mult_2(@list_0x10000)
  # end
end