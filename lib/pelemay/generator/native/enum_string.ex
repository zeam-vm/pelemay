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

    info
    |> Map.update(:arg_num, nil, fn _ -> 3 end)
    |> Util.push_impl_info(true)

    """
    static ERL_NIF_TERM
    #{nif_name}(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      return enum_string_replace(env, argv[0], argv[1], argv[2], true);
    }
    """
  end
end
