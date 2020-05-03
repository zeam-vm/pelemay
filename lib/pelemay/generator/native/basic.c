#define FAIL 0
#define SUCCESS 1
#define EMPTY 0
#define CACHE_LINE_SIZE 64
#define SIZE_T_MAX -1
#define INIT_SIZE_INT64 (CACHE_LINE_SIZE / sizeof(ErlNifSInt64))
#define INIT_SIZE_DOUBLE (CACHE_LINE_SIZE / sizeof(double))
#define SIZE_T_HIGHEST_BIT (~(SIZE_T_MAX >> 1))

#define loop_vectorize_width 4

int enif_get_int64_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, ErlNifSInt64 **vec, size_t *vec_l);
int enif_get_double_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, double **vec, size_t *vec_l);
int enif_get_double_vec_from_number_list(ErlNifEnv *env, ERL_NIF_TERM list, double **vec, size_t *vec_l);
int enif_get_range(ErlNifEnv *env, ERL_NIF_TERM list, ErlNifSInt64 *from, ErlNifSInt64 *to);
int enif_get_term_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, ERL_NIF_TERM **vec, unsigned *vec_l);
int get_replace_option(ErlNifEnv *env, ERL_NIF_TERM options, int *global);
int string_replace_binary(ErlNifBinary subject, ErlNifBinary pattern, ErlNifBinary replacement, bool global, ErlNifBinary *object);
int get_replace_option(ErlNifEnv *env, ERL_NIF_TERM options, int *global);

ERL_NIF_TERM enif_make_list_from_int64_vec(ErlNifEnv *env, const ErlNifSInt64 *vec, const size_t vec_l);
ERL_NIF_TERM enif_make_list_from_double_vec(ErlNifEnv *env, const double *vec, const size_t vec_l);
ERL_NIF_TERM enif_make_list_from_term_vec(ErlNifEnv *env, ERL_NIF_TERM *vec, const unsigned vec_l);
ERL_NIF_TERM string_replace(ErlNifEnv *env, ERL_NIF_TERM subject, ERL_NIF_TERM pattern, ERL_NIF_TERM replacement, bool global);
ERL_NIF_TERM enum_string_replace(ErlNifEnv *env, ERL_NIF_TERM subject, ERL_NIF_TERM pattern, ERL_NIF_TERM replacement, bool global);

ERL_NIF_TERM
enif_make_list_from_int64_vec(ErlNifEnv *env, const ErlNifSInt64 *vec, const size_t vec_l)
{
  ERL_NIF_TERM list = enif_make_list(env, 0);
  for(size_t i = vec_l; i > 0; i--) {
    ERL_NIF_TERM tail = list;
    ERL_NIF_TERM head = enif_make_int64(env, vec[i - 1]);
    list = enif_make_list_cell(env, head, tail);
  }
  return list;
}

ERL_NIF_TERM
enif_make_list_from_double_vec(ErlNifEnv *env, const double *vec, const size_t vec_l)
{
  ERL_NIF_TERM list = enif_make_list(env, 0);
  for(size_t i = vec_l; i > 0; i--) {
    ERL_NIF_TERM tail = list;
    ERL_NIF_TERM head = enif_make_double(env, vec[i - 1]);
    list = enif_make_list_cell(env, head, tail);
  }
  return list;
}

ERL_NIF_TERM
enif_make_list_from_term_vec(ErlNifEnv *env, ERL_NIF_TERM *vec, const unsigned vec_l)
{
  ERL_NIF_TERM list = enif_make_list(env, 0);
  for(size_t i = vec_l; i > 0; i--) {
    list = enif_make_list_cell(env, vec[i - 1], list);
  }
  return list;
}

int
enif_get_int64_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, ErlNifSInt64 **vec, size_t *vec_l)
{
  ERL_NIF_TERM head, tail;

  if (__builtin_expect((enif_get_list_cell(env, list, &head, &tail) == FAIL),
                       true)) {
    if (__builtin_expect((enif_is_empty_list(env, list) == SUCCESS), true)) {
      *vec_l = EMPTY;
      *vec = NULL;
      return SUCCESS;
    }
    ErlNifSInt64 from, to;
    if (__builtin_expect((enif_get_range(env, list, &from, &to) == FAIL), false)) {
      return FAIL;
    }
    if (__builtin_expect((from <= to), true)) {
      *vec_l = (size_t)(to - from + 1);
    } else {
      *vec_l = (size_t)(from - to + 1);
    }
    *vec = (ErlNifSInt64 *)enif_alloc(sizeof(ErlNifSInt64) * *vec_l);
    if (__builtin_expect((*vec == NULL), false)) {
      return FAIL;
    }
    if (__builtin_expect((from <= to), true)) {
//#pragma clang loop vectorize(enable)
      for(size_t i = 0; i < *vec_l; i++) {
        *(*vec + i) = from + (ErlNifSInt64) i;
      }
    } else {
//#pragma clang loop vectorize(enable)
      for(size_t i = 0; i < *vec_l; i++) {
        *(*vec + i) = from - (ErlNifSInt64) i;
      }
    }
    return SUCCESS;
  }
  size_t n = INIT_SIZE_INT64;
  size_t nn = CACHE_LINE_SIZE;
  ErlNifSInt64 *t = (ErlNifSInt64 *)enif_alloc(nn);
  if (__builtin_expect((t == NULL), false)) {
    return FAIL;
  }

  size_t i = 0;
  ERL_NIF_TERM tmp[loop_vectorize_width];
  int tmp_r[loop_vectorize_width];
  while (true) {
#pragma clang loop vectorize(disable)
    for (size_t count = 0; count < loop_vectorize_width; count++) {
      tmp[count] = head;
      if (__builtin_expect(
              (enif_get_list_cell(env, tail, &head, &tail) == FAIL), false)) {
        for (size_t c = 0; c <= count; c++) {
          tmp_r[c] = enif_get_int64(env, tmp[c], &t[i++]);
        }
        int acc = true;
#pragma clang loop vectorize(enable)
        for (size_t c = 0; c <= count; c++) {
          acc &= (tmp_r[c] == SUCCESS);
        }
        if (__builtin_expect((acc == false), false)) {
          enif_free(t);
          return FAIL;
        }

        *vec_l = i;
        *vec = t;
        return SUCCESS;
      }
    }
    if (__builtin_expect((i > SIZE_T_MAX - loop_vectorize_width), false)) {
      enif_free(t);
      return FAIL;
    }
    if (__builtin_expect((i + loop_vectorize_width > n), false)) {
      size_t old_nn = nn;
      if (__builtin_expect(((nn & SIZE_T_HIGHEST_BIT) == 0), true)) {
        nn <<= 1;
        n <<= 1;
      } else {
        nn = SIZE_T_MAX;
        n = nn / sizeof(ErlNifSInt64);
      }
      ErlNifSInt64 *new_t = (ErlNifSInt64 *)enif_alloc(nn);
      if(__builtin_expect((new_t == NULL), false)) {
        enif_free(t);
        return FAIL;
      }
      memcpy(new_t, t, old_nn);
      enif_free(t);
      t = new_t;
    }
#pragma clang loop vectorize(enable) unroll(enable)
    for (size_t count = 0; count < loop_vectorize_width; count++) {
      tmp_r[count] = enif_get_int64(env, tmp[count], &t[i + count]);
    }
    int acc = true;
#pragma clang loop vectorize(enable) unroll(enable)
    for (size_t count = 0; count < loop_vectorize_width; count++) {
      acc &= (tmp_r[count] == SUCCESS);
    }
    if (__builtin_expect((acc == false), false)) {
      enif_free(t);
      return FAIL;
    }
    i += loop_vectorize_width;
  }
}

int
enif_get_double_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, double **vec, size_t *vec_l)
{
  ERL_NIF_TERM head, tail;

  if (__builtin_expect((enif_get_list_cell(env, list, &head, &tail) == FAIL),
                       true)) {
    if (__builtin_expect((enif_is_empty_list(env, list) == SUCCESS), true)) {
      *vec_l = EMPTY;
      *vec = NULL;
      return SUCCESS;
    }
    return FAIL;
  }
  size_t n = INIT_SIZE_INT64;
  size_t nn = CACHE_LINE_SIZE;
  double *t = (double *)enif_alloc(nn);
  if (__builtin_expect((t == NULL), false)) {
    return FAIL;
  }

  size_t i = 0;
  ERL_NIF_TERM tmp[loop_vectorize_width];
  int tmp_r[loop_vectorize_width];
  while (true) {
#pragma clang loop vectorize(disable)
    for (size_t count = 0; count < loop_vectorize_width; count++) {
      tmp[count] = head;
      if (__builtin_expect(
              (enif_get_list_cell(env, tail, &head, &tail) == FAIL), false)) {
        for (size_t c = 0; c <= count; c++) {
          tmp_r[c] = enif_get_double(env, tmp[c], &t[i++]);
        }
        int acc = true;
#pragma clang loop vectorize(enable)
        for (size_t c = 0; c <= count; c++) {
          acc &= (tmp_r[c] == SUCCESS);
        }
        if (__builtin_expect((acc == false), false)) {
          enif_free(t);
          return FAIL;
        }

        *vec_l = i;
        *vec = t;
        return SUCCESS;
      }
    }
    if (__builtin_expect((i > SIZE_T_MAX - loop_vectorize_width), false)) {
      enif_free(t);
      return FAIL;
    }
    if (__builtin_expect((i + loop_vectorize_width > n), false)) {
      size_t old_nn = nn;
      if (__builtin_expect(((nn & SIZE_T_HIGHEST_BIT) == 0), true)) {
        nn <<= 1;
        n <<= 1;
      } else {
        nn = SIZE_T_MAX;
        n = nn / sizeof(ErlNifSInt64);
      }
      double *new_t = (double *)enif_alloc(nn);
      if(__builtin_expect((new_t == NULL), false)) {
        enif_free(t);
        return FAIL;
      }
      memcpy(new_t, t, old_nn);
      enif_free(t);
      t = new_t;
    }
#pragma clang loop vectorize(enable) unroll(enable)
    for (size_t count = 0; count < loop_vectorize_width; count++) {
      tmp_r[count] = enif_get_double(env, tmp[count], &t[i + count]);
    }
    int acc = true;
#pragma clang loop vectorize(enable) unroll(enable)
    for (size_t count = 0; count < loop_vectorize_width; count++) {
      acc &= (tmp_r[count] == SUCCESS);
    }
    if (__builtin_expect((acc == false), false)) {
      enif_free(t);
      return FAIL;
    }
    i += loop_vectorize_width;
  }
}

int
enif_get_term_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, ERL_NIF_TERM **vec, unsigned *vec_l)
{
  if (__builtin_expect(enif_is_empty_list(env, list), false)) {
    *vec_l = EMPTY;
    *vec = NULL;
    return true;
  }
  if (__builtin_expect(!enif_get_list_length(env, list, vec_l), false)) {
    return false;
  }
  *vec = enif_alloc(sizeof(ERL_NIF_TERM) * (*vec_l));
  if (__builtin_expect(*vec == NULL, false)) {
    return false;
  }
  ERL_NIF_TERM *head = *vec;
  ERL_NIF_TERM tail = list;
#pragma clang loop vectorize_width(loop_vectorize_width)
  for(size_t i = 0; i < *vec_l; i++) {
    if (__builtin_expect(!enif_get_list_cell(env, tail, head, &tail), false)) {
      return false;
    }
    head++;
  }
  return true;
}

int
enif_get_double_vec_from_number_list(ErlNifEnv *env, ERL_NIF_TERM list, double **vec, size_t *vec_l)
{
  ERL_NIF_TERM head, tail;

  if (__builtin_expect((enif_get_list_cell(env, list, &head, &tail) == FAIL),
                       true)) {
    if (__builtin_expect((enif_is_empty_list(env, list) == SUCCESS), true)) {
      *vec_l = EMPTY;
      *vec = NULL;
      return SUCCESS;
    }
    return FAIL;
  }
  size_t n = INIT_SIZE_INT64;
  size_t nn = CACHE_LINE_SIZE;
  double *t = (double *)enif_alloc(nn);
  if (__builtin_expect((t == NULL), false)) {
    return FAIL;
  }

  size_t i = 0;
  while (true) {
    if (__builtin_expect((enif_get_double(env, head, &t[i]) == FAIL), false)) {
      ErlNifSInt64 tmp;
      if (__builtin_expect((enif_get_int64(env, head, &tmp) == FAIL), false)) {
        enif_free(t);
        return FAIL;
      }
      t[i] = (double)tmp;
    }
    i++;
    if (__builtin_expect(
          (enif_get_list_cell(env, tail, &head, &tail) == FAIL), false)) {
      *vec_l = i;
      *vec = t;
      return SUCCESS;
    }
    if (__builtin_expect((i >= n), false)) {
      size_t old_nn = nn;
      if (__builtin_expect(((nn & SIZE_T_HIGHEST_BIT) == 0), true)) {
        nn <<= 1;
        n <<= 1;
      } else {
        nn = SIZE_T_MAX;
        n = nn / sizeof(ErlNifSInt64);
      }
      double *new_t = (double *)enif_alloc(nn);
      if (__builtin_expect((new_t == NULL), false)) {
        enif_free(t);
        return FAIL;
      }
      memcpy(new_t, t, old_nn);
      enif_free(t);
      t = new_t;
    }
  }
}

int
enif_get_range(ErlNifEnv *env, ERL_NIF_TERM map, ErlNifSInt64 *from, ErlNifSInt64 *to)
{
  ERL_NIF_TERM value; 
  if(__builtin_expect((enif_get_map_value(env, map, atom_struct, &value) == FAIL), false)) {
    return FAIL;
  }
  if(__builtin_expect(!enif_is_identical(value, atom_range), false)) {
    return FAIL;
  }
  if(__builtin_expect((enif_get_map_value(env, map, atom_first, &value) == FAIL), false)) {
    return FAIL;
  }
  if(__builtin_expect((enif_get_int64(env, value, from) == FAIL), false)) {
    return FAIL;
  }
  if(__builtin_expect((enif_get_map_value(env, map, atom_last, &value) == FAIL), false)) {
    return FAIL;
  }
  if(__builtin_expect((enif_get_int64(env, value, to) == FAIL), false)) {
    return FAIL;
  }
  return SUCCESS;
}

int string_replace_binary(ErlNifBinary subject, ErlNifBinary pattern, ErlNifBinary replacement, bool global, ErlNifBinary *object)
{
  if(__builtin_expect(!enif_alloc_binary(subject.size, object), false)) {
    return false;
  }
  unsigned subject_i = 0, object_i = 0;
#pragma clang loop vectorize_width(loop_vectorize_width)
  while(subject_i < subject.size) {
    while(subject_i < subject.size && subject.data[subject_i] != pattern.data[0]) {
      object->data[object_i++] = subject.data[subject_i++];
    }
    if(__builtin_expect(subject_i >= subject.size, false)) {
      return true;
    }
    unsigned pattern_i = 0;
    while(subject_i + pattern_i < subject.size
      && pattern_i < pattern.size 
      && subject.data[subject_i + pattern_i] == pattern.data[pattern_i]) {
      pattern_i++;
    }
    if(__builtin_expect(pattern_i == pattern.size, true)) {
      if(__builtin_expect(pattern.size != replacement.size, false)) {
        if(__builtin_expect(!enif_realloc_binary(object, object->size - pattern.size + replacement.size), false)) {
          return false;
        }
      }
      subject_i += pattern.size;
      for(unsigned replacement_i = 0; replacement_i < replacement.size; replacement_i++) {
        object->data[object_i++] = replacement.data[replacement_i];
      }
      if(__builtin_expect(!global, false)) {
        while(subject_i < subject.size) {
          object->data[object_i++] = subject.data[subject_i++];
        }
        return true;
      }
    } else if(__builtin_expect(subject_i < subject.size, true)) {
      object->data[object_i++] = subject.data[subject_i++];
    } else {
      return true;
    }
  }
  return true;
}

ERL_NIF_TERM string_replace(ErlNifEnv *env, ERL_NIF_TERM subject, ERL_NIF_TERM pattern, ERL_NIF_TERM replacement, bool global)
{
  ErlNifBinary subject_binary;
  if(__builtin_expect(!enif_inspect_binary(env, subject, &subject_binary), false)) {
    return enif_make_badarg(env);
  }
  ErlNifBinary pattern_binary;
  if(__builtin_expect(!enif_inspect_binary(env, pattern, &pattern_binary), false)) {
    return enif_make_badarg(env);
  }
  ErlNifBinary replacement_binary;
  if(__builtin_expect(!enif_inspect_binary(env, replacement, &replacement_binary), false)) {
    return enif_make_badarg(env);
  }
  ErlNifBinary object_binary;
  if(__builtin_expect(!string_replace_binary(subject_binary, pattern_binary, replacement_binary, global, &object_binary), false)) {
    return enif_make_badarg(env);
  }
  return enif_make_binary(env, &object_binary);
}

ERL_NIF_TERM enum_string_replace(ErlNifEnv *env, ERL_NIF_TERM subject, ERL_NIF_TERM pattern, ERL_NIF_TERM replacement, bool global)
{
  ERL_NIF_TERM *subject_vec;
  unsigned vec_l;
  if(__builtin_expect(!enif_get_term_vec_from_list(env, subject, &subject_vec, &vec_l), false)) {
    return enif_make_badarg(env);
  }
  ERL_NIF_TERM *object_vec;
  object_vec = enif_alloc(sizeof(ERL_NIF_TERM) * vec_l);
  if(__builtin_expect(object_vec == NULL, false)) {
    enif_free(subject_vec);
    return enif_make_badarg(env);
  }
#pragma clang loop vectorize_width(loop_vectorize_width)
  for(unsigned i = 0; i < vec_l; i++) {
    object_vec[i] = string_replace(env, subject_vec[i], pattern, replacement, global);
  } 
  ERL_NIF_TERM result = enif_make_list_from_term_vec(env, object_vec, vec_l);
  enif_free(subject_vec);
  enif_free(object_vec);
  return result;
}

int get_replace_option(ErlNifEnv *env, ERL_NIF_TERM options, int *global)
{
  *global = true;
  if(__builtin_expect(!enif_is_empty_list(env, options), false)) {
    ERL_NIF_TERM tail = options;
    unsigned vec_len;
    if(__builtin_expect(!enif_get_list_length(env, tail, &vec_len), false)) {
      return false;
    }
    ERL_NIF_TERM vec[vec_len];
    unsigned i = vec_len;
    while(enif_get_list_cell(env, tail, &vec[--i], &tail));
    for(int i = 0; i < vec_len; i++) {
      int arity;
      const ERL_NIF_TERM *array;
      if(__builtin_expect(!enif_get_tuple(env, vec[i], &arity, &array), false)) {
        return false;
      }
      if(__builtin_expect(arity != 2, false)) {
        return false;
      }
      unsigned key_len, value_len;
      if(__builtin_expect(!enif_get_atom_length(env, array[0], &key_len, ERL_NIF_LATIN1), false)) {
        return false;
      }
      if(__builtin_expect(!enif_get_atom_length(env, array[1], &value_len, ERL_NIF_LATIN1), false)) {
        return false;
      }
      char key_buf[key_len + 1], value_buf[value_len + 1];
      if(__builtin_expect(!enif_get_atom(env, array[0], key_buf, key_len + 1, ERL_NIF_LATIN1), false)) {
        return false;
      }
      if(__builtin_expect(!enif_get_atom(env, array[1], value_buf, value_len + 1, ERL_NIF_LATIN1), false)) {
        return false;
      }
      if(__builtin_expect(strcmp("global", key_buf) == 0, true)) {
        if(__builtin_expect(strcmp("false", value_buf) == 0, true)) {
          *global = false;
        } else if(__builtin_expect(strcmp("true", value_buf) == 0, true)) {
          *global = true;
        }
      }
    }
  }
  return true;
}


