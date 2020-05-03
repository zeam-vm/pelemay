defmodule Mix.Tasks.Pelemay.Clean do
  use Mix.Task

  @shortdoc "Deletes generated application files by Pelemay"
  @recursive true

  @moduledoc """
  Deletes generated application files by Pelemay.
  """

  @impl true
  def run(_) do
    Mix.Project.build_path()
    |> Path.dirname()
    |> Path.join("**/pelemay/priv/*")
    |> Path.wildcard()
    |> Enum.each(&File.rm_rf/1)
  end
end
