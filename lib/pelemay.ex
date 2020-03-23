defmodule Pelemay do
  alias Pelemay.Generator
  alias Pelemay.Db

  require Logger

  @log_path "#{Mix.Project.build_path()}/log/info.log"
  @compile_time_info "#{Mix.Project.build_path()}/log/compile_time_info"

  @on_load :init

  def init() do
    File.mkdir(Path.dirname(@log_path))
    File.mkdir(Path.dirname(@compile_time_info))
    File.rm(@log_path)
    File.touch(@log_path)
    :ok
  end

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

    def string_replace(list) do
      list
      |> Enum.map(& String.replace(&1, "Fizz", "Buzz"))
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
  defmacro defpelemay(functions) do
    Logger.add_backend({Pelemay.Logger, @log_path})
    File.write!(@compile_time_info, "compile_time_info = #{CpuInfo.all_profile() |> inspect()}")

    Db.init()

    ret = Optimizer.replace(functions, __CALLER__.module)

    Generator.generate(__CALLER__.module)
    result = Optimizer.consist_context(ret)

    Logger.flush()

    result
  end

  def compile_time_info() do
    File.read!(@compile_time_info)
  end
end
