defmodule GeneratedCodeTest do
  use ExUnit.Case, async: true
  require Pelemay

  test "Ensure loaded? test/support/sample.ex" do
    assert Code.ensure_loaded?(Sample)
  end

  describe "Input one list" do
    test "One Enum.map/2: list_square" do
      assert [1, 4, 9] == Sample.list_square([1, 2, 3])
    end

    test "two Enum.map/2: list_plus1_mult2" do
      assert [4, 6, 8] == Sample.list_plus1_mult2([1, 2, 3])
    end

    test "Other Enum-Funtion/2" do
      assert [[1], [2, 2], [3], [4, 4, 6], [7, 7]] ==
               Sample.list_chunk_by([1, 2, 2, 3, 4, 4, 6, 7, 7], &(rem(&1, 2) == 1))

      assert [[1, 2], [3, 4]] == Sample.list_chunk_every([1, 2, 3, 4], 2)
    end

    test "One Enum.reduce/3" do
      assert 6 == Sample.list_reduce_sum([1, 2, 3])
    end

    test "Various Enum funcions" do
      assert [2, 4, 6] == Sample.list_mult_sort([3, 1, 2])
    end

    test "RAISE: Various Type List" do
      assert_raise ArgumentError, fn ->
        Sample.list_square([1.0, 2, 3])
      end
    end
  end

  describe "Input lists" do
    test "One Enum.zip" do
      assert [{1, 3}, {2, 4}] == Sample.list_zip([1, 2], [3, 4])
    end
  end
end
