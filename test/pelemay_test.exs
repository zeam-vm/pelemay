defmodule PelemayTest do
  use ExUnit.Case, async: true
  doctest Pelemay
  doctest Pelemay.Db

  import Pelemay
  require Pelemay

  test "Ensure loaded?" do
    assert Code.ensure_loaded?(Pelemay)
  end

  describe "Input function definition with one list" do
    test "one Enum.map" do
      function =
        quote do
          def list_plus1(list) do
            list
            |> Enum.map(&(&1 + 1))
          end
        end

      optimized_func =
        quote do
          defpelemay do
            unquote(function)
          end
        end
        |> Macro.expand_once(__ENV__)
        |> Keyword.get(:do)
        |> Macro.to_string()

      expected =
        quote do
          def list_plus1(list) do
            list
            |> PelemayNifElixirPelemayTest.map_elem_plus_1()
          end
        end
        |> Macro.to_string()

      assert expected == optimized_func
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

      optimized_func =
        quote do
          defpelemay do
            unquote(function)
          end
        end
        |> Macro.expand_once(__ENV__)
        |> Keyword.get(:do)
        |> Macro.to_string()

      expected =
        quote do
          def list_plus1_twice(list) do
            list
            |> PelemayNifElixirPelemayTest.map_elem_plus_1()
            |> PelemayNifElixirPelemayTest.map_elem_mult_2()
          end
        end
        |> Macro.to_string()

      assert expected == optimized_func
    end

    test "Other Enum Funtions" do
      function =
        quote do
          def chunk_every(list) do
            list
            |> Enum.chunk_every()
          end
        end

      no_change =
        quote do
          defpelemay do
            unquote(function)
          end
        end
        |> Macro.expand_once(__ENV__)
        |> Keyword.get(:do)
        |> Macro.to_string()

      expected =
        quote do
          def chunk_every(list) do
            list
            |> Enum.chunk_every()
          end
        end
        |> Macro.to_string()

      assert expected == no_change
    end
  end
end
