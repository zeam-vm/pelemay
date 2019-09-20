defmodule Pelemay.Generator do
  alias Pelemay.Generator.Interface
  alias Pelemay.Generator.Native
  alias Pelemay.Generator.Makefile

  def module_replaced_non(module) do
    module |> Atom.to_string() |> String.replace(".", "")
  end

  def module_replaced_underscore(module) do
    module |> Atom.to_string() |> String.replace(".", "_")
  end

  def elixir_nif_module(module) do
    "Elixir.PelemayNif#{module_replaced_non(module)}"
  end

  def module_downcase_underscore(module) do
    module |> module_replaced_underscore() |> String.downcase()
  end

  def stub(module) do
    Application.app_dir(:pelemay, "priv/pelemay_nif_#{module_downcase_underscore(module)}.ex")
  end

  def ebin do
    Application.app_dir(:pelemay, "ebin")
  end

  def generate(module) do
    Application.app_dir(:pelemay, "priv")
    |> File.mkdir()

    Interface.generate(module)
    Native.generate(module)
    Makefile.generate(module)
  end
end
