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

  def nif_module(module) do
    "PelemayNif#{module_replaced_non(module)}"
  end

  def module_downcase_non(module) do
    module |> module_replaced_non() |> String.downcase()
  end

  def module_downcase_underscore(module) do
    module |> module_replaced_underscore() |> String.downcase()
  end

  def libnif_name(module) do
    "libnif#{module_downcase_non(module)}"
  end

  def libnif_priv_name(module) do
    "priv/libnif#{module_downcase_non(module)}"
  end

  def libnif(module) do
    Application.app_dir(:pelemay, libnif_priv_name(module))
  end

  def libc(module) do
    Application.app_dir(:pelemay, "#{libnif_priv_name(module)}.c")
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
