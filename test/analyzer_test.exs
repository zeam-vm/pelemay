defmodule AnalyzerTest do
  use ExUnit.Case, async: true
  doctest Analyzer

  @subject Analyzer

  describe "supported?/1" do
    test "with pipe, anonymous function: fn, one argument" do
      quoted = quote do: [1, 2, 3] |> Enum.map(fn x -> x + 1 end)

      assert {:|>, [context: _, import: Kernel], [[1, 2, 3], right]} = quoted
      assert {_enum_map, [], anonymous_function} = right
      assert [func: 
        %{
          args: [{:x, [], AnalyzerTest}, 1], 
          operators: [:+]}] == @subject.supported?(anonymous_function)
    end

    test "with pipe, anonymous function: fn, two arguments" do
      quoted = quote do: [1, 2, 3] |> Enum.map(fn x, y -> x + y + 1 end)

      assert {:|>, [context: _, import: Kernel], [[1, 2, 3], right]} = quoted
      assert {_enum_map, [], anonymous_function} = right

      assert  [func:  
            %{
               args: [{:x, [], AnalyzerTest}, {:y, [], AnalyzerTest}, 1],
               operators: [:+, :+]
             }] == @subject.supported?(anonymous_function)
    end

    test "with anonymous function: fn, one argument" do
      quoted = quote do: Enum.map([1, 2, 3], fn x -> x + 1 end)

      assert {_enum_map, [], [[1, 2, 3], anonymous_function]} = quoted
      assert [func: %{
        args: [{:x, [], AnalyzerTest}, 1], 
        operators: [:+]
      }] == @subject.supported?(anonymous_function)
    end

    test "with anonymous function: fn, two arguments" do
      quoted = quote do: Enum.map([1, 2, 3], fn x, y -> x + y + 1 end)

      assert {_enum_map, [], [[1, 2, 3], anonymous_function]} = quoted
      assert [func: %{
               args: [{:x, [], AnalyzerTest}, {:y, [], AnalyzerTest}, 1],
               operators: [:+, :+]
             }] == @subject.supported?(anonymous_function)
    end

    test "with basic types w/o tuples" do
      assert {:error, 1} == @subject.supported?(1)
      assert {:error, [1]} == @subject.supported?([1])
      assert {:error, true} == @subject.supported?(true)
      assert {:error, "1"} == @subject.supported?("1")
      assert {:error, '1'} == @subject.supported?('1')
      assert {:error, :a} == @subject.supported?(:a)
    end

    test "with one-element-tuple" do
      quoted = quote do: {1}

      assert {:error, quoted} == @subject.supported?(quoted)
    end

    test "with two-elements-tuple" do
      quoted = quote do: {1, 2}

      assert {:error, quoted} == @subject.supported?(quoted)
    end

    test "with three-elements-tuple" do
      quoted = quote do: {1, 2, 3}

      assert {:error, quoted} == @subject.supported?(quoted)
    end
  end

  describe "polynomial_map" do
    test "with two terms and one plus operator" do
      expr = quote do: 1 + 2.0

      assert [func: %{
               operators: [:+],
               args: [1, 2.0]
             }] == @subject.polynomial_map(expr)
    end

    test "with two terms is composed of one number and one captured val, which chained by one plus operator" do
      expr = quote do: &1 + 2

      assert [func: %{
               operators: [:+],
               args: [{:&, [], [1]}, 2]
             }] == @subject.polynomial_map(expr)
    end

    test "with two terms is composed of one number and one parameter, which chained by one plus operator" do
      expr = quote do: x + 2

      assert [func: %{
               operators: [:+],
               args: [{:x, [], AnalyzerTest}, 2]
             }] == @subject.polynomial_map(expr)
    end
  end
end
