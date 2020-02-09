defmodule Pelemay.Generator.Native.Enum do
  alias Pelemay.Generator.Native.Util, as: Util

  def map(%{nif_name: nif_name, args: args, operators: operators}) do
    expr_d = Util.make_expr(operators, args, "double")
    expr_l = Util.make_expr(operators, args, "long")

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

  # # Add here
  def sort(%{nif_name: nif_name, args: args, operators: operators}) do
  end

  def filter(%{nif_name: nif_name, args: args, operators: operators}) do
  end
end
