defmodule Pelemay_CL do
  alias Pelemay.Generator
  alias Pelemay.Db

  @moduledoc """
  ## Pelemay: The Penta (Five) “Elemental Way”: Freedom, Insight, Beauty, Efficiency and Robustness

  For example, the following code of the function `map_square` will be compiled to native code using SIMD instructions by Pelemay.

  ```elixir
  defmodule M do
    require Pelemay
    import Pelemay

    defpelemay do
      def map_square (list) do
        list
        |> Enum.map(& &1 * &1)
      end
    end
  ```

  1. Find Enum.map with a specific macro
  2. Analyze internal anonymous functions
  3. Register(ETS) following information as Map.
    - Module
    - Original function name
    - Function name for NIF
    - Value of Anonymous Function
  4. Insert NIF in AST
  5. Do Step 1 ~ 4 to each macro
  6. Receiving Map from ETS, and...
  7. Generate NIF Code
  8. Generate Elixir's functions
  9. Compile NIF as Custom Mix Task, using Clang
  """
  defmacro defpelemaycl(functions) do
    Db.init()

    caller_name =
      __CALLER__.module
      |> Generator.elixir_nif_module()
      |> String.to_atom()

    functions
    |> Optimizer.replace(caller_name)
    |> pelemaystub(__CALLER__.module)
  end

  defp pelemaystub(ret, module) do
    Generator.generate(module)
    ret
  end
end
