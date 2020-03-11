defmodule AnalyzerTest do
  use ExUnit.Case, async: true
  doctest Analyzer

  @subject Analyzer
  @context AnalyzerTest

  describe "supported?/1" do
    test "with pipe, anonymous function: fn, one argument" do
      quoted = quote do: [1, 2, 3] |> Enum.map(fn x -> x + 1 end)

      assert {:|>, [context: _, import: Kernel], [[1, 2, 3], right]} = quoted
      assert {_enum_map, [], anonymous_function} = right

      assert [func: %{args: [{:&, [], [1]}, 1], operators: [:+]}] ==
               @subject.parse(anonymous_function)
    end

    test "with pipe, anonymous function: fn, two arguments" do
      quoted = quote do: [1, 2, 3] |> Enum.sort(&(&1 >= &2))

      assert {:|>, [context: @context, import: Kernel], [[1, 2, 3], enum_func]} = quoted
      assert {_enum_sort, [], func} = enum_func

      assert @subject.parse(func) == [
               func: %{
                 args: [{:&, [], [1]}, {:&, [], [2]}],
                 operators: [:>=]
               }
             ]
    end

    test "with anonymous function: fn, one argument" do
      quoted = quote do: Enum.map([1, 2, 3], fn x -> x + 1 end)

      assert {_enum_map, [], [[1, 2, 3], func]} = quoted

      assert @subject.supported?(func) == [
               func: %{
                 args: [{:&, [], [1]}, 1],
                 operators: [:+]
               }
             ]
    end

    test "with anonymous function: fn, two arguments" do
      quoted = quote do: Enum.sort([1, 2, 3], fn x, y -> x >= y end)

      assert {enum_sort, [], [[1, 2, 3], func]} = quoted

      assert @subject.supported?(func) == [
               func: %{
                 args: [{:&, [], [1]}, {:&, [], [2]}],
                 operators: [:>=]
               }
             ]
    end

    test "with basic types w/o tuples" do
      assert [var: 1] == @subject.parse(1)
      assert [var: [1]] == @subject.parse([1])
      assert [var: true] == @subject.parse(true)
      assert [var: "1"] == @subject.parse("1")
      assert [var: '1'] == @subject.parse('1')
      assert [var: :a] == @subject.parse(:a)
    end

    test "with one-element-tuple" do
      quoted = quote do: {1}

      assert [var: quoted] == @subject.supported?(quoted)
    end

    test "with two-elements-tuple" do
      quoted = quote do: {1, 2}

      assert [var: quoted] == @subject.supported?(quoted)
    end

    test "with three-elements-tuple" do
      quoted = quote do: {1, 2, 3}

      assert [var: quoted] == @subject.supported?(quoted)
    end
  end

  describe "polynomial_map" do
    test "with two terms and one plus operator" do
      expr = quote do: 1 + 2.0

      assert [
               func: %{
                 operators: [:+],
                 args: [1, 2.0]
               }
             ] == @subject.polynomial_map(expr)
    end

    test "with two terms is composed of one number and one captured val, which chained by one plus operator" do
      expr = quote do: &1 + 2

      assert [
               func: %{
                 operators: [:+],
                 args: [{:&, [], [1]}, 2]
               }
             ] == @subject.polynomial_map(expr)
    end

    test "with two terms is composed of one number and one parameter, which chained by one plus operator" do
      expr = quote do: x + 2

      assert [
               func: %{
                 operators: [:+],
                 args: [{:x, [], AnalyzerTest}, 2]
               }
             ] == @subject.polynomial_map(expr)
    end
  end
end
