defmodule Pelemay.Generator.Native.EnumString do
  alias Pelemay.Generator.Native.Util, as: Util
  alias Pelemay.Db

  def map_replace(info) do
    %{
      nif_name: nif_name,
      args: [
        func: %{
          args: args,
          operators: operators
        }
      ]
    } = info

    Util.push_impl_info(info, true)

    
  end
end