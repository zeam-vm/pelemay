const int fail = 0;
const int success = 1;
const int empty = 0;
const size_t cache_line_size = 64;

int enif_get_long_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, long *vec, unsigned int vec_l);
int enif_get_double_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, double *vec, unsigned int vec_l);
ERL_NIF_TERM enif_make_list_from_long_vec(ErlNifEnv *env, const long *vec, const unsigned int vec_l);
ERL_NIF_TERM enif_make_list_from_double_vec(ErlNifEnv *env, const double *vec, const unsigned int vec_l);

ERL_NIF_TERM
enif_make_list_from_double_vec(ErlNifEnv *env, const double *vec, const unsigned int vec_l)
{
  ERL_NIF_TERM list = enif_make_list(env, 0);
  for(int i = vec_l; i > 0; i--) {
    ERL_NIF_TERM tail = list;
    ERL_NIF_TERM head = enif_make_double(env, vec[i - 1]);
    list = enif_make_list_cell(env, head, tail);
  }
  return list;
}

ERL_NIF_TERM
enif_make_list_from_long_vec(ErlNifEnv *env, const long *vec, const unsigned int vec_l)
{
  ERL_NIF_TERM list = enif_make_list(env, 0);
  for(int i = vec_l; i > 0; i--) {
    ERL_NIF_TERM tail = list;
    ERL_NIF_TERM head = enif_make_long(env, vec[i - 1]);
    list = enif_make_list_cell(env, head, tail);
  }
  return list;
}


int
enif_get_long_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, long *vec, unsigned int vec_l)
{
  ERL_NIF_TERM head, tail;

  int tmp_r = 1;
  for(int i=0; i<vec_l; i++){
      enif_get_list_cell(env, list, &head, &tail);
      tmp_r = enif_get_long(env, head, &vec[i]);
      list = tail;
      if (__builtin_expect((tmp_r == false), false)) {
        return fail;
      }
  }
  return success;
}

int 
enif_get_double_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, double *vec, unsigned int vec_l)
{
  ERL_NIF_TERM head, tail;

  int tmp_r = 1;
  for(int i=0; i<vec_l; i++){
      enif_get_list_cell(env, list, &head, &tail);
      tmp_r = enif_get_double(env, head, &vec[i]);
      list = tail;
      if (__builtin_expect((tmp_r == false), false)) {
        return fail;
      }
  }
  return success;
}