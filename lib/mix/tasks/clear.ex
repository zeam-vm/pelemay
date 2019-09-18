defmodule Mix.Tasks.Pelemay do
  use Mix.Task

  @shortdoc "Remove Glue functions"
  def run(_) do
  	File.rm(Application.app_dir(:pelemay, "priv/generated.mk"))
    File.rm("lib/interact_nif.ex")
    :ok
  end
end
