defmodule PelemayTest do
  use ExUnit.Case
  doctest Pelemay

  test "greets the world" do
    assert Pelemay.hello() == :world
  end
end
