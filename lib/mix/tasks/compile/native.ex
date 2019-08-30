defmodule Mix.Tasks.Compile.Native do
  use Mix.Task

  def run(_) do
    File.mkdir_p("priv")
    Mix.shell.cmd("make priv/libnif.so")
    :ok
  end
end