static ERL_NIF_TERM
chunk_every(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
  if (__builtin_expect((argc != 2), false)) {
    return enif_make_badarg(env);
  }
  ErlNifUInt64 c;
  if (__builtin_expect((enif_get_uint64(env, argv[1], &c) == FAIL), false)) {
    return enif_make_badarg(env);
  }
  size_t count = (size_t)c;
  if(count > SIZE_T_MAX / sizeof(ERL_NIF_TERM)) {
    return enif_make_badarg(env);
  }
  ErlNifSInt64 first, last;
  if(__builtin_expect((enif_get_range(env, argv[0], &first, &last) == SUCCESS), false)) {
    if(__builtin_expect((first == last), false)) {
      ERL_NIF_TERM value = enif_make_int64(env, first);
      return enif_make_list1(env, enif_make_list1(env, value));
    }
    size_t n = CACHE_LINE_SIZE / sizeof(ERL_NIF_TERM);
    size_t nn = CACHE_LINE_SIZE;
    ERL_NIF_TERM *ll = (ERL_NIF_TERM *)enif_alloc(nn);
    if(__builtin_expect(ll == NULL, false)) {
      return enif_make_badarg(env);
    }
    size_t li = 0;
    ERL_NIF_TERM *t = (ERL_NIF_TERM *)enif_alloc(count * sizeof(ERL_NIF_TERM));
    if(__builtin_expect(t == NULL, false)) {
      enif_free(ll);
      return enif_make_badarg(env);
    }
    if(__builtin_expect((first < last), true)) {
      ErlNifUInt64 c = 0;
      for(ErlNifSInt64 i = first; i <= last; i++) {
        if(c >= count) {
          ERL_NIF_TERM l = enif_make_list(env, 0);
          for(; c > 0; c--) {
            l = enif_make_list_cell(env, t[c - 1], l);
          }
          ll[li++] = l;
          if (__builtin_expect((li >= n), false)) {
            size_t old_nn = nn;
            if (__builtin_expect(((nn & SIZE_T_HIGHEST_BIT) == 0), true)) {
              nn <<= 1;
              n <<= 1;
            } else {
              nn = SIZE_T_MAX;
              n = nn / sizeof(ERL_NIF_TERM);
            }
            ERL_NIF_TERM *new_ll = (ERL_NIF_TERM *)enif_alloc(nn);
            if (__builtin_expect((new_ll == NULL), false)) {
              enif_free(ll);
              enif_free(t);
              return enif_make_badarg(env);
            }
            memcpy(new_ll, ll, old_nn);
            enif_free(ll);
            ll = new_ll;
          }
        }
        t[c++] = enif_make_int64(env, i);
      }
      ERL_NIF_TERM l = enif_make_list(env, 0);
      for(; c > 0; c--) {
        l = enif_make_list_cell(env, t[c - 1], l);
      }
      ll[li++] = l;
      l = enif_make_list(env, 0);
      for(; li > 0; li--) {
        l = enif_make_list_cell(env, ll[li - 1], l);
      }
      enif_free(ll);
      enif_free(t);
      return l;
    } else {
      ErlNifUInt64 c = 0;
      for(ErlNifSInt64 i = first; i >= last; i--) {
        if(c >= count) {
          ERL_NIF_TERM l = enif_make_list(env, 0);
          for(; c > 0; c--) {
            l = enif_make_list_cell(env, t[c - 1], l);
          }
          ll[li++] = l;
          if (__builtin_expect((li >= n), false)) {
            size_t old_nn = nn;
            if (__builtin_expect(((nn & SIZE_T_HIGHEST_BIT) == 0), true)) {
              nn <<= 1;
              n <<= 1;
            } else {
              nn = SIZE_T_MAX;
              n = nn / sizeof(ERL_NIF_TERM);
            }
            ERL_NIF_TERM *new_ll = (ERL_NIF_TERM *)enif_alloc(nn);
            if (__builtin_expect((new_ll == NULL), false)) {
              enif_free(ll);
              enif_free(t);
              return enif_make_badarg(env);
            }
            memcpy(new_ll, ll, old_nn);
            enif_free(ll);
            ll = new_ll;
          }
        }
        t[c++] = enif_make_int64(env, i);
      }
      ERL_NIF_TERM l = enif_make_list(env, 0);
      for(; c > 0; c--) {
        l = enif_make_list_cell(env, t[c - 1], l);
      }
      ll[li++] = l;
      l = enif_make_list(env, 0);
      for(; li > 0; li--) {
        l = enif_make_list_cell(env, ll[li - 1], l);
      }
      enif_free(ll);
      enif_free(t);
      return l;
    }
  }
  ERL_NIF_TERM list, head, tail;
  list = argv[0];
  if (__builtin_expect((enif_get_list_cell(env, list, &head, &tail) == FAIL), true)) {
    if (__builtin_expect((enif_is_empty_list(env, list) == SUCCESS), true)) {
      return list;
    } else {
      return enif_make_badarg(env);
    }
  }
  size_t n = CACHE_LINE_SIZE / sizeof(ERL_NIF_TERM);
  size_t nn = CACHE_LINE_SIZE;
  ERL_NIF_TERM *ll = (ERL_NIF_TERM *)enif_alloc(nn);
  if(__builtin_expect(ll == NULL, false)) {
    return enif_make_badarg(env);
  }
  size_t li = 0;
  ERL_NIF_TERM *t = (ERL_NIF_TERM *)enif_alloc(count * sizeof(ERL_NIF_TERM));
  if(__builtin_expect(t == NULL, false)) {
    enif_free(ll);
    return enif_make_badarg(env);
  }
  while(true) {
    for(size_t i = 0; i < count; i++) {
      t[i] = head;
      if (__builtin_expect((enif_get_list_cell(env, tail, &head, &tail) == FAIL), false)) {
        ERL_NIF_TERM l = enif_make_list(env, 0);
        i++;
        for(; i > 0; i--) {
          l = enif_make_list_cell(env, t[i - 1], l);
        }
        ll[li++] = l;
        l = enif_make_list(env, 0);
        for(; li > 0; li--) {
          l = enif_make_list_cell(env, ll[li - 1], l);
        }
        enif_free(ll);
        enif_free(t);
        return l;
      }
    }
    ERL_NIF_TERM l = enif_make_list(env, 0);
    for(size_t i = count; i > 0; i--) {
      l = enif_make_list_cell(env, t[i - 1], l);
    }
    ll[li++] = l;
    if (__builtin_expect((li >= n), false)) {
      size_t old_nn = nn;
      if (__builtin_expect(((nn & SIZE_T_HIGHEST_BIT) == 0), true)) {
        nn <<= 1;
        n <<= 1;
      } else {
        nn = SIZE_T_MAX;
        n = nn / sizeof(ERL_NIF_TERM);
      }
      ERL_NIF_TERM *new_ll = (ERL_NIF_TERM *)enif_alloc(nn);
      if (__builtin_expect((new_ll == NULL), false)) {
        enif_free(ll);
        enif_free(t);
        return enif_make_badarg(env);
      }
      memcpy(new_ll, ll, old_nn);
      enif_free(ll);
      ll = new_ll;
    }
  }
}