static ERL_NIF_TERM
add(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
  if (__builtin_expect((argc != 2), false)) {
    return enif_make_badarg(env);
  }
  ErlNifSInt64 v1, v2;
  if (__builtin_expect((enif_get_int64(env, argv[0], &v1) == FAIL), false)) {
    return enif_make_badarg(env);
  }
  if (__builtin_expect((enif_get_int64(env, argv[1], &v2) == FAIL), false)) {
    return enif_make_badarg(env);
  }
  return enif_make_int64(env, v1 + v2);
}