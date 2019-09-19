defmodule PelemayTest do
  use ExUnit.Case, async: true
  doctest Pelemay

  test "Basic functional testing for Pelemay" do
  	result = 1..4 |> Enum.to_list |> PelemayTest.Sample.map_square
  	assert result == [1, 4, 9, 16]
  end
end

defmodule PelemayTest.Sample do
  require Pelemay
  import Pelemay

  defpelemay do
    def map_square list do
      list |> Enum.map(& &1 * &1)
    end
  end
end