defmodule Pelemay.Generator do
  alias Pelemay.Generator.Interface
  alias Pelemay.Generator.Native
  alias Pelemay.Generator.Builder

  require Logger

  @doc """

  ## Examples

    iex> Pelemay.Generator.module_replaced_non(:"Elixir.Module")
    "ElixirModule"

  """
  def module_replaced_non(module) do
    module |> Atom.to_string() |> String.replace(".", "")
  end

  @doc """

  ## Examples

    iex> Pelemay.Generator.module_replaced_underscore(:"Elixir.Module")
    "Elixir_Module"
    
  """
  def module_replaced_underscore(module) do
    module |> Atom.to_string() |> String.replace(".", "_")
  end

  @doc """

  ## Examples

    iex> Pelemay.Generator.nif_module(:"Elixir.Module")
    "PelemayNifElixirModule"

  """
  def nif_module(module) do
    "PelemayNif#{module_replaced_non(module)}"
  end

  @doc """

  ## Examples

    iex> Pelemay.Generator.elixir_nif_module(:"Elixir.Module")
    "Elixir.PelemayNifElixirModule"
    
  """
  def elixir_nif_module(module) do
    "Elixir.PelemayNif#{module_replaced_non(module)}"
  end

  @doc """

  ## Examples

    iex> Pelemay.Generator.module_downcase_non(:"Elixir.Module")
    "elixirmodule"
    
  """
  def module_downcase_non(module) do
    module |> module_replaced_non() |> String.downcase()
  end

  @doc """

  ## Examples

    iex> Pelemay.Generator.module_downcase_underscore(:"Elixir.Module")
    "elixir_module"
    
  """
  def module_downcase_underscore(module) do
    module |> module_replaced_underscore() |> String.downcase()
  end

  @doc """

  ## Examples

    iex> Pelemay.Generator.libnif_name(:"Elixir.Module")
    "libnifelixirmodule"
    
  """
  def libnif_name(module) do
    "libnif#{module_downcase_non(module)}"
  end

  @doc """

  ## Examples

    iex> Pelemay.Generator.libnif_priv_name(:"Elixir.Module")
    "priv/libnifelixirmodule"
    
  """
  def libnif_priv_name(module) do
    "priv/#{libnif_name(module)}"
  end

  def libnif_src_name(module) do
    "src/#{libnif_name(module)}"
  end

  def libnif(module) do
    Application.app_dir(:pelemay, libnif_priv_name(module))
  end

  def libc(module) do
    Application.app_dir(:pelemay, "#{libnif_src_name(module)}.c")
  end

  def libso(module) do
    case :os.type() do
      {:win32, :nt} -> Application.app_dir(:pelemay, "#{libnif_priv_name(module)}.dll")
      _ -> Application.app_dir(:pelemay, "#{libnif_priv_name(module)}.so")
    end
  end

  def build_dir() do
    Application.app_dir(:pelemay, "build")
  end

  def obj_dir() do
    Application.app_dir(:pelemay, "obj")
  end

  def src_dir() do
    Application.app_dir(:pelemay, "src")
  end

  def priv_dir() do
    Application.app_dir(:pelemay, "priv")
  end

  def makefile(module) do
    Application.app_dir(:pelemay, "build/#{libnif_name(module)}.mk")
  end

  def stub(module) do
    Application.app_dir(:pelemay, "priv/pelemay_nif_#{module_downcase_underscore(module)}.ex")
  end

  def ebin do
    Application.app_dir(:pelemay, "ebin")
  end

  def kernel_name(nif_name) do
    "#{nif_name}_kernel"
  end

  def kernel_driver_name(nif_name) do
    "#{nif_name}_kernel_driver"
  end

  def kernel_h(nifname) do
    "#{kernel_name(nifname)}.h"
  end

  def kernel_h_macro(nifname) do
    "#{kernel_name(nifname)}_H" |> String.upcase()
  end

  def kernel_dh(nifname) do
    "#{kernel_driver_name(nifname)}.h"
  end

  def kernel_dh_macro(nifname) do
    "#{kernel_driver_name(nifname)}_H" |> String.upcase()
  end

  def kernel_c(nifname) do
    "#{kernel_name(nifname)}.c"
  end

  def kernel_dc(nifname) do
    "#{kernel_driver_name(nifname)}.c"
  end

  def kernel_o(nifname) do
    "#{kernel_name(nifname)}.o"
  end

  def kernel_do(nifname) do
    "#{kernel_driver_name(nifname)}.o"
  end

  def full_path_kernel_h(nifname) do
    src_dir() <> "/" <> kernel_h(nifname)
  end

  def full_path_kernel_dh(nifname) do
    src_dir() <> "/" <> kernel_dh(nifname)
  end

  def full_path_kernel_c(nifname) do
    src_dir() <> "/" <> kernel_c(nifname)
  end

  def full_path_kernel_dc(nifname) do
    src_dir() <> "/" <> kernel_dc(nifname)
  end

  def generate(module) do
    File.mkdir(priv_dir())
    File.mkdir(src_dir())
    File.mkdir(build_dir())
    File.mkdir(obj_dir())

    case Native.generate(module) do
      {:error, message} ->
        Logger.warn(message)

      :ok ->
        Interface.generate(module)
        Builder.generate(module)
    end
  end
end
