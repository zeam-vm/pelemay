defmodule SumMagTest do
  use ExUnit.Case, async: true
  doctest SumMag

  test "check support func" do
    ast =
      quote do
        [1, 2]
        |> Enum.map(&(&1 + 1))
      end

    assert true == SumMag.include_specified_func?(ast, :Enum, :map)
  end

  test "check un-support func" do
    ast =
      quote do
        Enum.zip([1, 2], [3, 4])
      end

    assert nil == SumMag.include_specified_func?(ast, :Enum, :map)
  end

  test "check support funcions" do
    ast =
      quote do
        [1, 2]
        |> Enum.map(&(&1 + 1))
        |> Enum.map(&(&1 + 2))
      end

    assert %{map: 2} == SumMag.include_specified_functions?(ast, :Enum, [:map])
  end

  test "check support various funcions" do
    ast =
      quote do
        Enum.zip([1, 2], [3, 4])
        |> Enum.map(& &1)
      end

    assert %{map: 1, zip: 1} == SumMag.include_specified_functions?(ast, :Enum, [:map, :zip])
  end
end
