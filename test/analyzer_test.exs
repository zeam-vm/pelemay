defmodule AnalyzerAFuncTest do
  use ExUnit.Case, async: true

  @subject Analyzer.AFunc

  describe "supported?/1" do
    test "with pipe, anonymous function: fn, one argument" do
      quoted = quote do: [1, 2, 3] |> Enum.map(fn x -> x + 1 end)

      assert {:|>, [context: _, import: Kernel], [[1, 2, 3], right]} = quoted
      assert {_, [], anonymous_function} = right
      assert {:ok, other} = @subject.supported?(anonymous_function)
    end

    test "with anonymous function: fn, one argument" do
      quoted = quote do: Enum.map([1, 2, 3], fn x -> x + 1 end)
      assert {_, [], [[1, 2, 3], anonymous_function]} = quoted

      assert {:other, anonymous_function} == @subject.supported?(anonymous_function)
    end
  end
end
