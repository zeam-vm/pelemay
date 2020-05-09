defmodule Mix.Tasks.Pelemay.Bench do
  use Mix.Task

  @shortdoc "Benchmark kernels of Pelemay"
  @recursive true

  @moduledoc """
  Benchmark kernels of Pelemay.

  ```
    mix pelemay.bench `module_name`
  ```
  """

  @impl true
  def run(args) do
    Mix.Project.get!()
    args
    |> Enum.map(& "Elixir.#{&1}")
    |> Enum.map(& String.to_atom(&1))
    |> Enum.map(& Pelemay.Generator.nif_module(&1))
    |> Enum.each(& Mix.Shell.cmd("mix run -e \"#{&1}.bench() |> IO.inspect()\"", fn x -> IO.puts(x) end))
  end
end
