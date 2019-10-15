defmodule PelemayTest do
  use ExUnit.Case, async: true
  doctest Pelemay
  doctest Pelemay.Db

  import Pelemay
  require Pelemay

  defp apply_pelemay(function) do
    quote do
      defpelemay do
        unquote(function)
      end
    end
    |> Macro.expand_once(__ENV__)
    |> Keyword.get(:do)
  end

  test "Ensure loaded?" do
    assert Code.ensure_loaded?(Pelemay)
  end

  describe "Input: one list" do
    test "One Enum.map" do
      function =
        quote do
          def list_plus1(list) do
            list
            |> Enum.map(&(&1 + 1))
          end
        end

      optimized_func = apply_pelemay(function)

      expected =
        quote do
          def list_plus1(list) do
            list
            |> PelemayNifElixirPelemayTest.map_elem_plus_1()
          end
        end
        |> Macro.to_string()

      assert expected == Macro.to_string(optimized_func)
    end

    test "two Enum.map" do
      function =
        quote do
          def list_plus1_twice(list) do
            list
            |> Enum.map(&(&1 + 1))
            |> Enum.map(&(&1 * 2))
          end
        end

      optimized_func = apply_pelemay(function)

      expected =
        quote do
          def list_plus1_twice(list) do
            list
            |> PelemayNifElixirPelemayTest.map_elem_plus_1()
            |> PelemayNifElixirPelemayTest.map_elem_mult_2()
          end
        end
        |> Macro.to_string()

      assert expected == Macro.to_string(optimized_func)
    end

    test "Other Enum Funtion" do
      function =
        quote do
          def chunk_every(list) do
            list
            |> Enum.chunk_every()
          end
        end

      no_change = apply_pelemay(function)

      expected = Macro.to_string(function)

      assert expected == Macro.to_string(no_change)
    end

    test "Various Enum funcions" do
      function =
        quote do
          def mult_sort(list) do
            list
            |> Enum.map(&(&1 * 2))
            |> Enum.sort()
          end
        end

      optimized_func = apply_pelemay(function)

      expected =
        quote do
          def mult_sort(list) do
            list
            |> PelemayNifElixirPelemayTest.map_elem_mult_2()
            |> Enum.sort()
          end
        end
        |> Macro.to_string()

      assert expected == Macro.to_string(optimized_func)
    end
  end

  describe "Inputs: two list" do
    test "One Enum.zip" do
      function =
        quote do
          def mult_sort(a, b) do
            list
            |> Enum.zip(a, b)
          end
        end

      no_change = apply_pelemay(function)

      expected = Macro.to_string(function)

      assert expected == Macro.to_string(no_change)
    end
  end
end
