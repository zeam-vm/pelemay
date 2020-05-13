#ifndef BASIC_H
#define BASIC_H

#include <stdbool.h>
#include <pelemay_base.h>
#include <erl_nif.h>

#define FAIL 0
#define SUCCESS 1
#define EMPTY 0
#define CACHE_LINE_SIZE 64
#define SIZE_T_MAX -1
#define INIT_SIZE_INT64 (CACHE_LINE_SIZE / sizeof(ErlNifSInt64))
#define INIT_SIZE_DOUBLE (CACHE_LINE_SIZE / sizeof(double))
#define SIZE_T_HIGHEST_BIT (~(SIZE_T_MAX >> 1))

ERL_NIF_TERM atom_struct;
ERL_NIF_TERM atom_range;
ERL_NIF_TERM atom_first;
ERL_NIF_TERM atom_last;

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

#endif // BASIC_H
