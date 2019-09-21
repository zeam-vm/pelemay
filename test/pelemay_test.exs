defmodule PelemayTest do
  use ExUnit.Case, async: true
  doctest Pelemay

  test "Basic functional testing for Pelemay" do
    result = 1..4 |> Enum.to_list() |> PelemayTest.Sample.map_square()
    assert result == [1, 4, 9, 16]
  end
end
