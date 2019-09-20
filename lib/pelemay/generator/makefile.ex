defmodule Pelemay.Generator.Makefile do
  alias Pelemay.Generator

  def generate(module) do
    prefix_str = """
    # This file was generated by Pelemay.Generator.Makefile
    TARGET_LIBS := \
    """

    str = " $(PREFIX)/#{Generator.libnif_name(module)}.so"

    file = Application.app_dir(:pelemay, "priv/generated.mk")

    unless File.exists?(file) do
      file |> File.write(prefix_str)
    end

    file |> File.write(str, [:append])
  end
end
