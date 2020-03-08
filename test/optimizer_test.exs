defmodule OptimizerTest do
  use ExUnit.Case, async: true
  doctest Optimizer

  alias Pelemay.Db

  setup_all do
    Db.init()

    :ok
  end

  describe "Argumets of inner function" do
    test "No inner function" do
      polynomial_map = [func: %{operators: [:+], args: [{:&, [], 1}, 1]}]
      assert Optimizer.generate_arguments(polynomial_map) == []
    end

    test "Inner function is String.replace/3" do
      polynomial_map = %{
        args: [
          {:&, [], [1]},
          {:pattern, [], nil},
          {:replacement, [], nil}
        ],
        operators: ["String.replace"]
      }

      assert Optimizer.generate_arguments(polynomial_map) ==
               [{:pattern, [], nil}, {:replacement, [], nil}]
    end
  end

  test "verify" do
  end

  test "replace_function" do
    func_name = "map_elem1_plus_1"
    polymap = [func: %{args: [{:&, [], [1]}, 1], operators: [:*]}]

    ret = Optimizer.replace_function(func_name, polymap)

    assert ret ==
             {
               {:., [], [{:__aliases__, [alias: false], [:ReplaceModule]}, :map_elem1_plus_1]},
               [],
               []
             }
  end

  describe "Check data on ETS" do
    test "format" do
      # polymap = [func: %{args: [{:&, [], [1]}, 1], operators: [:*]}]
      # module_info = [Enum: [map: 1]]
      # ret = Optimizer.format(polymap, module_info)
    end

    test "init" do
    end

    test "extract_module_informations" do
    end

    test "parallerize_term" do
    end

    test "accelerate_expr" do
    end
  end
end
