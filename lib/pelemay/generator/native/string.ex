defmodule Pelemay.Generator.Native.String do
  alias Pelemay.Generator.Native.Util, as: Util

  def replace(info) do
    %{
      nif_name: nif_name,
      module: _,
      function: _,
      arg_num: _,
      args: args
    } = info

    info
    |> Map.update(:arg_num, nil, fn _ -> 3 end)
    |> Util.push_impl_info(true)

    args |> Keyword.get_values(:var)

    """
    static
    ERL_NIF_TERM #{nif_name}(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      if(__builtin_expect(argc != 3, false)) {
        return enif_make_badarg(env);
      }
      bool global = true;
      return string_replace(env, argv[0], argv[1], argv[2], global);
    }
    """
  end
end
