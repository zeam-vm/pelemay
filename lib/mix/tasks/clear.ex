defmodule Mix.Tasks.Clear do
  use Mix.Task

  @shortdoc "Remove Glue functions"
  def run (_) do
    File.rm "lib/interact_nif.ex"
    :ok
  end
end