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
    "priv/libnif#{module_downcase_non(module)}"
  end

  def libnif(module) do
    Application.app_dir(:pelemay, libnif_priv_name(module))
  end

  def libc(module) do
    Application.app_dir(:pelemay, "#{libnif_priv_name(module)}.c")
  end

  def libso(module) do
    case :os.type() do
      {:win32, :nt} -> Application.app_dir(:pelemay, "#{libnif_priv_name(module)}.dll")
      _ -> Application.app_dir(:pelemay, "#{libnif_priv_name(module)}.so")
    end
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

    case Native.generate(module) do
      {:error, message} ->
        Logger.warn(message)

      :ok ->
        Interface.generate(module)
        Builder.generate(module)
    end
  end
end
