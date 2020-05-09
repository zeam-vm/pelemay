defmodule Mix.Tasks.Pelemay.Nerves.Bench do
  use Mix.Task

  @shortdoc "Benchmark kernels of Pelemay with ssh nerves.local"
  @recursive true

  @moduledoc """
  Benchmark kernels of Pelemay with ssh nerves.local.

  ```
    mix pelemay.nerves.bench `module_name`
  ```
  """

  @impl true
  def run(args) do
    Mix.Project.get!()

    args
    |> Enum.map(&"Elixir.#{&1}")
    |> Enum.map(&String.to_atom(&1))
    |> Enum.map(&Pelemay.Generator.nif_module(&1))
    |> Enum.each(&Mix.Shell.cmd("ssh nerves.local \"#{&1}.bench()\"", fn x -> IO.puts(x) end))
  end
end
