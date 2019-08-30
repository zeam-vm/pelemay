defmodule LogisticMapBench do
  use Benchfella

  @list_0x1000  (1..0x1000) |> Enum.to_list

  bench "Enum" do
    @list_0x1000
    |> Sample.enum_logistic_map
  end

  bench "Flow" do
    @list_0x1000
    |> Sample.flow_logistic_map
  end

  bench "Accelerated" do
    @list_0x1000
    |> Sample.logistic_map
  end
end