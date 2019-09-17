defmodule Pelemay.Generator do
  alias Pelemay.Generator.Interface
  alias Pelemay.Generator.Native
  alias Pelemay.Generator.Makefile

  def generate(module) do
    Application.app_dir(:pelemay, "priv")
    |> File.mkdir()

    Interface.generate(module)
    Native.generate(module)
    Makefile.generate(module)
  end
end
