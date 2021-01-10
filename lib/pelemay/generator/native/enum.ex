defmodule Pelemay.Generator.Native.Enum do
  alias Pelemay.Generator, as: Generator
  alias Pelemay.Generator.Native.Util, as: Util
  alias Pelemay.Db

  def map(module, info) do
    %{
      nif_name: nif_name,
      args: [
        func: %{
          args: args,
          operators: operators
        }
      ]
    } = info

    expr_d = Util.make_expr(operators, args, "double")
    expr_l = Util.make_expr(operators, args, "long")

    Util.push_impl_info(info, true, true)

    generate_kernel_h(nif_name)
    generate_kernel_base_h(nif_name)
    generate_kernel_driver_h(nif_name)
    generate_kernel_driver_base_h(nif_name)

    generate_kernel_c(nif_name, expr_d: expr_d, expr_l: expr_l)
    generate_kernel_base_c(nif_name, expr_d: expr_d, expr_l: expr_l)
    generate_kernel_driver_c(nif_name)
    generate_kernel_driver_base_c(nif_name)
    generate_kernel_bench_c(nif_name)
    generate_kernel_perf_c(nif_name)

    Db.append_kernel(nif_name)

    """
    #include "#{Generator.kernel_name(nif_name)}.h"
    #include "#{Generator.kernel_driver_name(nif_name)}.h"

    static ERL_NIF_TERM
    #{nif_name}_yielding_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

    static ERL_NIF_TERM
    #{nif_name}_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      ErlNifTime start = enif_monotonic_time(ERL_NIF_USEC);

      if (__builtin_expect((argc != 1), false)) {
        return enif_make_badarg(env);
      }

      struct #{Generator.priv_data(module)} *priv_data = (struct #{Generator.priv_data(module)} *)enif_priv_data(env);
      if (__builtin_expect((priv_data == NULL), false)) {
        return enif_make_badarg(env);
      }
      if (__builtin_expect((priv_data->#{Generator.resource_state(nif_name)} == NULL), false)) {
        return enif_make_badarg(env);
      }
      struct #{Generator.struct_state(nif_name)} *state = (struct #{Generator.struct_state(nif_name)} *)enif_alloc_resource(
        priv_data->#{Generator.resource_state(nif_name)},
        sizeof(struct #{Generator.struct_state(nif_name)})
      );
      if (__builtin_expect((state == NULL), false)) {
        return enif_make_badarg(env);
      }

      ErlNifBinary org_ptr;
      ErlNifSInt64 *vec_long;
      double *vec_double;
      // enif_fprintf(stderr, "start enif_get_int64_vec_from_list...");
      if (__builtin_expect((enif_get_int64_vec_from_list(env, argv[0], &vec_long, &state->vec_l) == FAIL), false)) {
        // enif_fprintf(stderr, "fail\\n");
        // enif_fprintf(stderr, "start enif_get_double_vec_from_list...");
        if (__builtin_expect((enif_get_double_vec_from_list(env, argv[0], &vec_double, &state->vec_l) == FAIL), false)) {
          // enif_fprintf(stderr, "fail\\n");
          return enif_make_badarg(env);
        }
        // enif_fprintf(stderr, "end\\n");
        state->is_double = true;
        if (__builtin_expect(!enif_alloc_binary(sizeof(double) * state->vec_l, &org_ptr), false)) {
          return enif_make_badarg(env);
        }
        memcpy(org_ptr.data, vec_double, org_ptr.size);
        enif_free(vec_double);
      } else {
        // enif_fprintf(stderr, "end\\n");
        state->is_double = false;
        // enif_fprintf(stderr, "vec_l: %llu\\n", state->vec_l);
        if (__builtin_expect(!enif_alloc_binary(sizeof(ErlNifSInt64) * state->vec_l, &org_ptr), false)) {
          return enif_make_badarg(env);
        }
        // enif_fprintf(stderr, "org_ptr.data: %p, org_ptr.size: %llu\\n", org_ptr.data, org_ptr.size);
        // enif_fprintf(stderr, "vec_long: %p\\n", vec_long);
        // enif_fprintf(stderr, "start memcpy...");
        memcpy(org_ptr.data, vec_long, org_ptr.size);
        // enif_fprintf(stderr, "done\\n");
        enif_free(vec_long);
      }
      state->count = 0;

      // enif_fprintf(stderr, "start enif_make_resource...");
      ERL_NIF_TERM state_term = enif_make_resource(env, state);
      // enif_fprintf(stderr, "done\\n");

      // enif_fprintf(stderr, "start slice_percent...");
      ErlNifTime consume_time = enif_monotonic_time(ERL_NIF_USEC) - start;
      int slice_percent = (consume_time * 100) / 1000;
      if(slice_percent < 0) {
        slice_percent = 0;
      } else if(slice_percent > 100) {
        slice_percent = 100;
      }
      // enif_fprintf(stderr, "%d\\n", slice_percent);
      enif_consume_timeslice(env, slice_percent);
      const ERL_NIF_TERM args[] = {state_term, enif_make_binary(env, &org_ptr)};

      // enif_fprintf(stderr, "start enif_schedule_nif...");
      return enif_schedule_nif(
        env,
        "#{nif_name}_yielding_nif",
        0,
        #{nif_name}_yielding_nif,
        2,
        args
      );
    }

    static ERL_NIF_TERM
    #{nif_name}_yielding_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      // enif_fprintf(stderr, "yielding_nif\\n");

      ErlNifTime start = enif_monotonic_time(ERL_NIF_USEC);

      if (__builtin_expect((argc != 2), false)) {
        return enif_make_badarg(env);
      }

      struct #{Generator.priv_data(module)} *priv_data = (struct #{Generator.priv_data(module)} *)enif_priv_data(env);
      if (__builtin_expect((priv_data == NULL), false)) {
        return enif_make_badarg(env);
      }
      if (__builtin_expect((priv_data->#{Generator.resource_state(nif_name)} == NULL), false)) {
        return enif_make_badarg(env);
      }
      struct #{Generator.struct_state(nif_name)} *state;
      if(__builtin_expect(!enif_get_resource(env, argv[0], priv_data->#{Generator.resource_state(nif_name)}, ((void*) (&state))), false)) {
        return enif_make_badarg(env);
      }
      if(__builtin_expect(state == NULL, false)) {
        return enif_make_badarg(env);
      }

      ErlNifBinary org_ptr;
      if(__builtin_expect(!enif_inspect_binary(env, argv[1], &org_ptr), false)) {
        return enif_make_badarg(env);
      }

      // enif_fprintf(stderr, "org_ptr.data: %p, org_ptr.size: %llu\\n", org_ptr.data, org_ptr.size);

      size_t chunk;
      // enif_fprintf(stderr, "state->count(%llu)\\n", state->count);
      chunk = min(state->vec_l - state->count, 1024);
      // enif_fprintf(stderr, "chunk(%llu)\\n", chunk);

      if(state->is_double) {
        double *vec_double = (double *)org_ptr.data;
        vec_double += state->count;
        #{Generator.kernel_name(nif_name)}_double(vec_double, chunk);
        state->count += chunk;
        // enif_fprintf(stderr, "state->count(%llu)\\n", state->count);
        if(state->count >= state->vec_l) {
          double *data = (double *)enif_alloc(org_ptr.size);
          memcpy(data, org_ptr.data, org_ptr.size);
          size_t vec_l = state->vec_l;
          enif_release_resource(state);
          // enif_fprintf(stderr, "return\\n");
          return enif_make_list_from_double_vec(env, data, vec_l);
        }
      } else {
        ErlNifSInt64 *vec_long = (ErlNifSInt64 *)org_ptr.data;
        vec_long += state->count;
        #{Generator.kernel_name(nif_name)}_i64(vec_long, chunk);
        state->count += chunk;
        // enif_fprintf(stderr, "state->count(%llu)\\n", state->count);
        if(state->count >= state->vec_l) {
          ErlNifSInt64 *data = (ErlNifSInt64 *)enif_alloc(org_ptr.size);
          memcpy(data, org_ptr.data, org_ptr.size);
          size_t vec_l = state->vec_l;
          enif_release_resource(state);
          // enif_fprintf(stderr, "return\\n");
          return enif_make_list_from_int64_vec(env, data, vec_l);
        }                 
      }

      ErlNifTime consume_time = enif_monotonic_time(ERL_NIF_USEC) - start;
      int slice_percent = (consume_time * 100) / 1000;
      if(slice_percent < 0) {
        slice_percent = 0;
      } else if(slice_percent > 100) {
        slice_percent = 100;
      }
      enif_consume_timeslice(env, slice_percent);
      return enif_schedule_nif(
        env,
        "#{nif_name}_yielding_nif",
        0,
        #{nif_name}_yielding_nif,
        argc,
        argv
      );
    }

    static ERL_NIF_TERM
    #{nif_name}_nif_driver_double(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      if (__builtin_expect((argc != 1), false)) {
        return enif_make_badarg(env);
      }
      ErlNifUInt64 vec_l;
      if (__builtin_expect((enif_get_uint64(env, argv[0], &vec_l) == FAIL), false)) {
        return enif_make_badarg(env);
      }
      ErlNifUInt64 *time = #{Generator.kernel_driver_name(nif_name)}_double((size_t) vec_l);
      ERL_NIF_TERM result = enif_make_tuple2(
        env,
        enif_make_uint64(env, time[0]),
        enif_make_uint64(env, time[1])
      );
      enif_free(time);
      return result;
    }

    static ERL_NIF_TERM
    #{nif_name}_nif_driver_lsm_double(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      if (__builtin_expect((argc != 0), false)) {
        return enif_make_badarg(env);
      }
      double *lsm = pelemay_lsm_drive(#{nif_name}_kernel_driver_double);
      ERL_NIF_TERM kl =
        enif_make_list2(
          env,
          enif_make_tuple2(
            env,
            enif_make_atom(env, "cycle"), 
            enif_make_list3(
              env,
              enif_make_tuple2(env, enif_make_atom(env, "r"), enif_make_double(env, lsm[0])),
              enif_make_tuple2(env, enif_make_atom(env, "a"), enif_make_double(env, lsm[1])),
              enif_make_tuple2(env, enif_make_atom(env, "b"), enif_make_double(env, lsm[2]))
            )),
          enif_make_tuple2(
            env, 
            enif_make_atom(env, "ns"), 
            enif_make_list3(
              env,
              enif_make_tuple2(env, enif_make_atom(env, "r"), enif_make_double(env, lsm[3])),
              enif_make_tuple2(env, enif_make_atom(env, "a"), enif_make_double(env, lsm[4])),
              enif_make_tuple2(env, enif_make_atom(env, "b"), enif_make_double(env, lsm[5]))
            ))
        );
      enif_free(lsm);
      return kl;
    }

    static ERL_NIF_TERM
    #{nif_name}_nif_driver_i64(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      if (__builtin_expect((argc != 1), false)) {
        return enif_make_badarg(env);
      }
      ErlNifUInt64 vec_l;
      if (__builtin_expect((enif_get_uint64(env, argv[0], &vec_l) == FAIL), false)) {
        return enif_make_badarg(env);
      }
      ErlNifUInt64 *time = #{Generator.kernel_driver_name(nif_name)}_i64((size_t) vec_l);
      ERL_NIF_TERM result = enif_make_tuple2(
        env,
        enif_make_uint64(env, time[0]),
        enif_make_uint64(env, time[1])
      );
      enif_free(time);
      return result;
    }


    static ERL_NIF_TERM
    #{nif_name}_nif_driver_lsm_i64(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      if (__builtin_expect((argc != 0), false)) {
        return enif_make_badarg(env);
      }
      double *lsm = pelemay_lsm_drive(#{nif_name}_kernel_driver_i64);
      ERL_NIF_TERM kl =
        enif_make_list2(
          env,
          enif_make_tuple2(
            env,
            enif_make_atom(env, "cycle"), 
            enif_make_list3(
              env,
              enif_make_tuple2(env, enif_make_atom(env, "r"), enif_make_double(env, lsm[0])),
              enif_make_tuple2(env, enif_make_atom(env, "a"), enif_make_double(env, lsm[1])),
              enif_make_tuple2(env, enif_make_atom(env, "b"), enif_make_double(env, lsm[2]))
            )),
          enif_make_tuple2(
            env, 
            enif_make_atom(env, "ns"), 
            enif_make_list3(
              env,
              enif_make_tuple2(env, enif_make_atom(env, "r"), enif_make_double(env, lsm[3])),
              enif_make_tuple2(env, enif_make_atom(env, "a"), enif_make_double(env, lsm[4])),
              enif_make_tuple2(env, enif_make_atom(env, "b"), enif_make_double(env, lsm[5]))
            ))
        );
      enif_free(lsm);
      return kl;
    }
    """
  end

  defp definition_struct_state(nif_name) do
    """
    struct #{Generator.struct_state(nif_name)} {
      size_t count;
      size_t vec_l;
      bool is_double;
    };
    """
  end

  defp generate_kernel_h(nif_name) do
    kernel_h = """
    // Generated by Pelemay.Generator.Native.Enum
    #ifndef #{Generator.kernel_macro(nif_name)}_H
    #define #{Generator.kernel_macro(nif_name)}_H
    #ifdef __cplusplus
    extern "C" {
    #endif // __cplusplus

    #include <stdlib.h>
    #include <stdbool.h>
    #include <erl_nif.h>

    #{definition_struct_state(nif_name)}

    void #{Generator.kernel_name(nif_name)}_double(double *vec_double, size_t vec_l);
    void #{Generator.kernel_name(nif_name)}_i64(ErlNifSInt64 *vec_long, size_t vec_l);

    #ifdef __cplusplus
    }
    #endif // __cplusplus
    #endif // #{Generator.kernel_macro(nif_name)}_H
    """

    File.write!("#{Generator.src_dir()}/#{Generator.kernel_name(nif_name)}.h", kernel_h)
  end

  defp generate_kernel_base_h(nif_name) do
    kernel_base_h = """
    // Generated by Pelemay.Generator.Native.Enum
    #ifndef #{Generator.kernel_macro(nif_name)}_BASE_H
    #define #{Generator.kernel_macro(nif_name)}_BASE_H
    #ifdef __cplusplus
    extern "C" {
    #endif // __cplusplus

    #include <stdbool.h>
    #include <pelemay_base.h>
    #include <erl_nif.h>

    #{definition_struct_state(nif_name)}

    void #{Generator.kernel_name(nif_name)}_double(double *vec_double, size_t vec_l);
    void #{Generator.kernel_name(nif_name)}_i64(int64_t *vec_long, size_t vec_l);

    #ifdef __cplusplus
    }
    #endif // __cplusplus
    #endif // #{Generator.kernel_macro(nif_name)}_BASE_H
    """

    File.write!("#{Generator.src_dir()}/#{Generator.kernel_name(nif_name)}_base.h", kernel_base_h)
  end

  defp generate_kernel_driver_h(nif_name) do
    kernel_dh = """
    // Generated by Pelemay.Generator.Native.Enum
    #ifndef #{Generator.kernel_driver_macro(nif_name)}_H
    #define #{Generator.kernel_driver_macro(nif_name)}_H

    #ifdef __cplusplus
    extern "C" {
    #endif // __cplusplus

    #include <erl_nif.h>

    ErlNifUInt64 *#{Generator.kernel_driver_name(nif_name)}_double(ErlNifUInt64 vec_l);
    ErlNifUInt64 *#{Generator.kernel_driver_name(nif_name)}_i64(ErlNifUInt64 vec_l);

    #ifdef __cplusplus
    }
    #endif // __cplusplus
    #endif // #{Generator.kernel_driver_macro(nif_name)}_H
    """

    File.write!("#{Generator.src_dir()}/#{Generator.kernel_driver_name(nif_name)}.h", kernel_dh)
  end

  def generate_kernel_driver_base_h(nif_name) do
    kernel_driver_base_h = """
    // Generated by Pelemay.Generator.Native.Enum
    #ifndef #{Generator.kernel_driver_macro(nif_name)}_BASE_H
    #define #{Generator.kernel_driver_macro(nif_name)}_BASE_H

    #ifdef __cplusplus
    extern "C" {
    #endif // __cplusplus

    #include <pelemay_base.h>

    uint64_t *#{Generator.kernel_driver_name(nif_name)}_double(uint64_t vec_l);
    uint64_t *#{Generator.kernel_driver_name(nif_name)}_i64(uint64_t vec_l);

    #ifdef __cplusplus
    }
    #endif // __cplusplus
    #endif // #{Generator.kernel_driver_macro(nif_name)}_BASE_H
    """

    File.write!(
      "#{Generator.src_dir()}/#{Generator.kernel_driver_name(nif_name)}_base.h",
      kernel_driver_base_h
    )
  end

  defp generate_kernel_c(nif_name, expr_d: expr_d, expr_l: expr_l) do
    kernel_c = """
    // Generated by Pelemay.Generator.Native.Enum

    #include <basic.h>
    #include "#{Generator.kernel_name(nif_name)}.h"

    #ifdef __cplusplus
    extern "C" {
    #endif // __cplusplus

    #include <erl_nif.h>

    void #{Generator.kernel_name(nif_name)}_double(double *vec_double, size_t vec_l)
    {
    #pragma clang loop vectorize_width(LOOP_VECTORIZE_WIDTH)
      for(size_t i = 0; i < vec_l; i++) {
        vec_double[i] = #{expr_d};
      }
    }

    void #{Generator.kernel_name(nif_name)}_i64(ErlNifSInt64 *vec_long, size_t vec_l)
    {
    #pragma clang loop vectorize_width(LOOP_VECTORIZE_WIDTH)
      for(size_t i = 0; i < vec_l; i++) {
        vec_long[i] = #{expr_l};
      }
    }

    #ifdef __cplusplus
    }
    #endif // __cplusplus
    """

    File.write!("#{Generator.src_dir()}/#{Generator.kernel_name(nif_name)}.c", kernel_c)
  end

  def generate_kernel_base_c(nif_name, expr_d: expr_d, expr_l: expr_l) do
    kernel_base_c = """
    // Generated by Pelemay.Generator.Native.Enum

    #include "#{Generator.kernel_name(nif_name)}_base.h"

    #ifdef __cplusplus
    extern "C" {
    #endif // __cplusplus

    #include <erl_nif.h>

    void #{Generator.kernel_name(nif_name)}_double(double *vec_double, size_t vec_l)
    {
    #pragma clang loop vectorize_width(LOOP_VECTORIZE_WIDTH)
      for(size_t i = 0; i < vec_l; i++) {
        vec_double[i] = #{expr_d};
      }
    }

    void #{Generator.kernel_name(nif_name)}_i64(int64_t *vec_long, size_t vec_l)
    {
    #pragma clang loop vectorize_width(LOOP_VECTORIZE_WIDTH)
      for(size_t i = 0; i < vec_l; i++) {
        vec_long[i] = #{expr_l};
      }
    }

    #ifdef __cplusplus
    }
    #endif // __cplusplus
    """

    File.write!("#{Generator.src_dir()}/#{Generator.kernel_name(nif_name)}_base.c", kernel_base_c)
  end

  defp generate_kernel_driver_c(nif_name) do
    kernel_driver_c = """
    // Generated by Pelemay.Generator.Native.Enum
    #include <clockcycle.h>
    #include <stdio.h> // int rand(void)
    #include <erl_nif.h>
    #include "#{Generator.kernel_name(nif_name)}.h"

    #ifdef __cplusplus
    extern "C" {
    #endif // __cplusplus
    ErlNifUInt64 *#{Generator.kernel_driver_name(nif_name)}_double(ErlNifUInt64 vec_l)
    {
      ErlNifUInt64 *result = (ErlNifUInt64 *)enif_alloc(sizeof(ErlNifUInt64) * 2);
      double *vec_double = (double *)enif_alloc(sizeof(double) * vec_l);
      for(ErlNifUInt64 i = 0; i < vec_l; i++) {
        vec_double[i] = (double)rand() / (rand() + 1);
      }
      ErlNifUInt64 start_time_cycle = now_cycle();
      ErlNifUInt64 start_time_ns = now_ns();
      #{Generator.kernel_name(nif_name)}_double(vec_double, vec_l);
      ErlNifUInt64 end_time_cycle = now_cycle();
      ErlNifUInt64 end_time_ns = now_ns();
      enif_free(vec_double);
      result[0] = end_time_cycle - start_time_cycle;
      result[1] = end_time_ns - start_time_ns;
      return result;
    }

    ErlNifUInt64 *#{Generator.kernel_driver_name(nif_name)}_i64(ErlNifUInt64 vec_l)
    {
      ErlNifUInt64 *result = (ErlNifUInt64 *)enif_alloc(sizeof(ErlNifUInt64) * 2);
      ErlNifSInt64 *vec_long = (ErlNifSInt64 *)enif_alloc(sizeof(ErlNifSInt64) * vec_l);
      for(ErlNifUInt64 i = 0; i < vec_l; i++) {
        vec_long[i] = rand();
      }
      ErlNifUInt64 start_time_cycle = now_cycle();
      ErlNifUInt64 start_time_ns = now_ns();
      #{Generator.kernel_name(nif_name)}_i64(vec_long, vec_l);
      ErlNifUInt64 end_time_cycle = now_cycle();
      ErlNifUInt64 end_time_ns = now_ns();
      enif_free(vec_long);
      result[0] = end_time_cycle - start_time_cycle;
      result[1] = end_time_ns - start_time_ns;
      return result;
    }
    #ifdef __cplusplus
    }
    #endif // __cplusplus
    """

    File.write!(
      "#{Generator.src_dir()}/#{Generator.kernel_driver_name(nif_name)}.c",
      kernel_driver_c
    )
  end

  defp generate_kernel_driver_base_c(nif_name) do
    kernel_driver_base_c = """
    // Generated by Pelemay.Generator.Native.Enum
    #include <clockcycle_base.h>
    #include <stdlib.h>
    #include <stdio.h> // int rand(void)
    #include "#{Generator.kernel_name(nif_name)}_base.h"

    #ifdef __cplusplus
    extern "C" {
    #endif // __cplusplus
    uint64_t *#{Generator.kernel_driver_name(nif_name)}_double(uint64_t vec_l)
    {
      uint64_t *result = (uint64_t *)malloc(sizeof(uint64_t) * 2);
      double *vec_double = (double *)malloc(sizeof(double) * vec_l);
      for(uint64_t i = 0; i < vec_l; i++) {
        vec_double[i] = (double)rand() / (rand() + 1);
      }
      uint64_t start_time_cycle = now_cycle();
      uint64_t start_time_ns = now_ns();
      #{Generator.kernel_name(nif_name)}_double(vec_double, vec_l);
      uint64_t end_time_cycle = now_cycle();
      uint64_t end_time_ns = now_ns();
      free(vec_double);
      result[0] = end_time_cycle - start_time_cycle;
      result[1] = end_time_ns - start_time_ns;
      return result;
    }

    uint64_t *#{Generator.kernel_driver_name(nif_name)}_i64(uint64_t vec_l)
    {
      uint64_t *result = (uint64_t *)malloc(sizeof(uint64_t) * 2);
      int64_t *vec_long = (int64_t *)malloc(sizeof(int64_t) * vec_l);
      for(uint64_t i = 0; i < vec_l; i++) {
        vec_long[i] = rand();
      }
      uint64_t start_time_cycle = now_cycle();
      uint64_t start_time_ns = now_ns();
      #{Generator.kernel_name(nif_name)}_i64(vec_long, vec_l);
      uint64_t end_time_cycle = now_cycle();
      uint64_t end_time_ns = now_ns();
      free(vec_long);
      result[0] = end_time_cycle - start_time_cycle;
      result[1] = end_time_ns - start_time_ns;
      return result;
    }
    #ifdef __cplusplus
    }
    #endif // __cplusplus
    """

    File.write!(
      "#{Generator.src_dir()}/#{Generator.kernel_driver_name(nif_name)}_base.c",
      kernel_driver_base_c
    )
  end

  defp generate_kernel_bench_c(nif_name) do
    kernel_bench_c = """
    // Generated by Pelemay.Generator.Native.Enum
    #include <stdlib.h>
    #include <stdio.h>
    #include <lsm_base.h>
    #include "#{Generator.kernel_driver_name(nif_name)}_base.h"

    int main() {
      double *result_double = pelemay_lsm_drive(#{Generator.kernel_driver_name(nif_name)}_double);
      double *result_i64 = pelemay_lsm_drive(#{Generator.kernel_driver_name(nif_name)}_i64);

      printf("#{Generator.kernel_name(nif_name)}_double: r_clock = %lf, a_clock = %lf, b_clock = %lf\\n", result_double[0], result_double[1], result_double[2]);
      printf("#{Generator.kernel_name(nif_name)}_double: r_ns = %lf, a_ns = %lf, b_ns = %lf\\n", result_double[3], result_double[4], result_double[5]);
      printf("#{Generator.kernel_name(nif_name)}_i64: r_clock = %lf, a_clock = %lf, b_clock = %lf\\n", result_i64[0], result_i64[1], result_i64[2]);
      printf("#{Generator.kernel_name(nif_name)}_i64: r_ns = %lf, a_ns = %lf, b_ns = %lf\\n", result_i64[3], result_i64[4], result_i64[5]);

      free(result_double);
      free(result_i64);
      return 0;
    }
    """

    File.write!(
      "#{Generator.src_dir()}/#{Generator.kernel_name(nif_name)}_bench.c",
      kernel_bench_c
    )
  end

  defp generate_kernel_perf_c(nif_name) do
    kernel_perf_c = """
    // Generated by Pelemay.Generator.Native.Enum
    #include <stdlib.h>
    #include <stdio.h>
    #include <stdint.h>
    #include <stdbool.h>
    #include <string.h>
    #include "#{Generator.kernel_driver_name(nif_name)}_base.h"

    int main(int argc, char *argv[]) {
      uint64_t length = 65536;
      bool is_double = false;
      if(argc >= 2) {
        if(strcmp("double", argv[1]) == 0) {
          is_double = true;
        }
      }
      if(argc >= 3) {
        length = atoi(argv[2]);
      }
      if(is_double) {
        #{Generator.kernel_driver_name(nif_name)}_double(length);
      } else {
        #{Generator.kernel_driver_name(nif_name)}_i64(length);
      }
      return 0;
    }
    """

    File.write!(
      "#{Generator.src_dir()}/#{Generator.kernel_name(nif_name)}_perf.c",
      kernel_perf_c
    )
  end

  def chunk_every(_module, info) do
    %{
      nif_name: nif_name,
      module: _,
      function: _,
      arg_num: _,
      args: _
    } = info

    {:ok, ret} = File.read(__DIR__ <> "/enum.c")

    Map.update(info, :arg_num, nil, fn _ -> 2 end)
    |> Util.push_impl_info(true, false)

    String.replace(ret, "chunk_every", "#{nif_name}_nif")
  end

  # Add here
  def sort(_module, info) do
    Util.push_impl_info(info, false, false)

    nil
  end

  def filter(_module, info) do
    Util.push_impl_info(info, false, false)

    nil
  end
end
