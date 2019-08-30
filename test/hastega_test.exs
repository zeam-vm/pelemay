defmodule HastegaTest do
  use ExUnit.Case
  doctest Hastega

  test "greets the world" do
    assert Hastega.hello() == :world
  end
end
