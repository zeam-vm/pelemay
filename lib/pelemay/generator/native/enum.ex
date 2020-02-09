defmodule Pelemay.Generator.Native.Enum do
  alias Pelemay.Generator.Native.Util, as: Util
  alias Pelemay.Db

  def map(%{nif_name: nif_name, args: args, operators: operators} = info) do
    expr_d = Util.make_expr(operators, args, "double")
    expr_l = Util.make_expr(operators, args, "long")

    Util.push_impl_info(info, true)

    """
    static ERL_NIF_TERM
    #{nif_name}(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      if (__builtin_expect((argc != 1), false)) {
        return enif_make_badarg(env);
      }
      ErlNifSInt64 *vec_long;
      size_t vec_l;
      double *vec_double;
      if (__builtin_expect((enif_get_int64_vec_from_list(env, argv[0], &vec_long, &vec_l) == fail), false)) {
        if (__builtin_expect((enif_get_double_vec_from_list(env, argv[0], &vec_double, &vec_l) == fail), false)) {
          return enif_make_badarg(env);
        }
    #pragma clang loop vectorize_width(loop_vectorize_width)
        for(size_t i = 0; i < vec_l; i++) {
          vec_double[i] = #{expr_d};
        }
        return enif_make_list_from_double_vec(env, vec_double, vec_l);
      }
    #pragma clang loop vectorize_width(loop_vectorize_width)
      for(size_t i = 0; i < vec_l; i++) {
        vec_long[i] = #{expr_l};
      }
      return enif_make_list_from_int64_vec(env, vec_long, vec_l);
    }
    """
  end

  def chunk_every(info) do
    %{
      nif_name: nif_name,
      module: _,
      function: _,
      arg_num: _,
      args: _,
      operators: _
    } = info

    {:ok, ret} = File.read(__DIR__ <> "/enum.c")

    Map.update(info, :impl, nil, fn _ -> true end)
    |> Map.update(:arg_num, nil, fn _ -> 2 end)
    |> Db.register()

    String.replace(ret, "chunk_every", "#{nif_name}")
  end

  # Add here
  def sort(info) do
    Util.push_impl_info(info, false)

    nil
  end

  def filter(info) do
    Util.push_impl_info(info, false)

    nil
  end
end
