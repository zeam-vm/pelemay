defmodule Pelemay.Generator do
  alias Pelemay.Generator.Interface
  alias Pelemay.Generator.Native

  def generate do
    Interface.generate
    Native.generate
  end
end