defmodule Mix.Tasks.Pelemay do
  use Mix.Task

  @shortdoc "Remove Glue functions"
  def run(_) do
    File.rm(Application.app_dir(:pelemay, "priv/pelemay_nif_*.ex") |> Path.wildcard())
    File.rm(Application.app_dir(:pelemay, "priv/generated.mk"))
    :ok
  end
end
