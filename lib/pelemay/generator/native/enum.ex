defmodule Pelemay.Generator.Native.Enum do
  alias Pelemay.Generator, as: Generator
  alias Pelemay.Generator.Native.Util, as: Util
  alias Pelemay.Db

  def map(info) do
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
    #{nif_name}_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      if (__builtin_expect((argc != 1), false)) {
        return enif_make_badarg(env);
      }
      ErlNifSInt64 *vec_long;
      size_t vec_l;
      double *vec_double;
      if (__builtin_expect((enif_get_int64_vec_from_list(env, argv[0], &vec_long, &vec_l) == FAIL), false)) {
        if (__builtin_expect((enif_get_double_vec_from_list(env, argv[0], &vec_double, &vec_l) == FAIL), false)) {
          return enif_make_badarg(env);
        }
        #{Generator.kernel_name(nif_name)}_double(vec_double, vec_l);
        return enif_make_list_from_double_vec(env, vec_double, vec_l);
      }
      #{Generator.kernel_name(nif_name)}_i64(vec_long, vec_l);
      return enif_make_list_from_int64_vec(env, vec_long, vec_l);
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
      ErlNifUInt64 time = #{Generator.kernel_driver_name(nif_name)}_double((size_t) vec_l);
      return enif_make_uint64(env, time);
    }

    static ERL_NIF_TERM
    #{nif_name}_nif_driver_lsm_double(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      if (__builtin_expect((argc != 0), false)) {
        return enif_make_badarg(env);
      }
      double *lsm = pelemay_lsm_drive(#{nif_name}_kernel_driver_double);
      ERL_NIF_TERM kl =
        enif_make_list3(
          env,
          enif_make_tuple2(env, enif_make_atom(env, "r"), enif_make_double(env, lsm[0])),
          enif_make_tuple2(env, enif_make_atom(env, "a"), enif_make_double(env, lsm[1])),
          enif_make_tuple2(env, enif_make_atom(env, "b"), enif_make_double(env, lsm[2]))
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
      ErlNifUInt64 time = #{Generator.kernel_driver_name(nif_name)}_i64((size_t) vec_l);
      return enif_make_uint64(env, time);
    }


    static ERL_NIF_TERM
    #{nif_name}_nif_driver_lsm_i64(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
    {
      if (__builtin_expect((argc != 0), false)) {
        return enif_make_badarg(env);
      }
      double *lsm = pelemay_lsm_drive(#{nif_name}_kernel_driver_i64);
      ERL_NIF_TERM kl =
        enif_make_list3(
          env,
          enif_make_tuple2(env, enif_make_atom(env, "r"), enif_make_double(env, lsm[0])),
          enif_make_tuple2(env, enif_make_atom(env, "a"), enif_make_double(env, lsm[1])),
          enif_make_tuple2(env, enif_make_atom(env, "b"), enif_make_double(env, lsm[2]))
        );
      enif_free(lsm);
      return kl;
    }
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
    #include <erl_nif.h>

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

    #include <pelemay_base.h>

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

    ErlNifUInt64 #{Generator.kernel_driver_name(nif_name)}_double(ErlNifUInt64 vec_l);
    ErlNifUInt64 #{Generator.kernel_driver_name(nif_name)}_i64(ErlNifUInt64 vec_l);

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

    uint64_t #{Generator.kernel_driver_name(nif_name)}_double(uint64_t vec_l);
    uint64_t #{Generator.kernel_driver_name(nif_name)}_i64(uint64_t vec_l);

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
    ErlNifUInt64 #{Generator.kernel_driver_name(nif_name)}_double(ErlNifUInt64 vec_l)
    {
      double *vec_double = (double *)enif_alloc(sizeof(double) * vec_l);
      for(ErlNifUInt64 i = 0; i < vec_l; i++) {
        vec_double[i] = (double)rand() / (rand() + 1);
      }
      ErlNifUInt64 start_time = now();
      #{Generator.kernel_name(nif_name)}_double(vec_double, vec_l);
      ErlNifUInt64 end_time = now();
      enif_free(vec_double);
      return end_time - start_time;
    }

    ErlNifUInt64 #{Generator.kernel_driver_name(nif_name)}_i64(ErlNifUInt64 vec_l)
    {
      ErlNifSInt64 *vec_long = (ErlNifSInt64 *)enif_alloc(sizeof(ErlNifSInt64) * vec_l);
      for(ErlNifUInt64 i = 0; i < vec_l; i++) {
        vec_long[i] = rand();
      }
      ErlNifUInt64 start_time = now();
      #{Generator.kernel_name(nif_name)}_i64(vec_long, vec_l);
      ErlNifUInt64 end_time = now();
      enif_free(vec_long);
      return end_time - start_time;
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
    #include <clockcycle.h>
    #include <stdlib.h>
    #include <stdio.h> // int rand(void)
    #include "#{Generator.kernel_name(nif_name)}_base.h"

    #ifdef __cplusplus
    extern "C" {
    #endif // __cplusplus
    uint64_t #{Generator.kernel_driver_name(nif_name)}_double(uint64_t vec_l)
    {
      double *vec_double = (double *)malloc(sizeof(double) * vec_l);
      for(uint64_t i = 0; i < vec_l; i++) {
        vec_double[i] = (double)rand() / (rand() + 1);
      }
      uint64_t start_time = now();
      #{Generator.kernel_name(nif_name)}_double(vec_double, vec_l);
      uint64_t end_time = now();
      free(vec_double);
      return end_time - start_time;
    }

    uint64_t #{Generator.kernel_driver_name(nif_name)}_i64(uint64_t vec_l)
    {
      int64_t *vec_long = (int64_t *)malloc(sizeof(int64_t) * vec_l);
      for(uint64_t i = 0; i < vec_l; i++) {
        vec_long[i] = rand();
      }
      uint64_t start_time = now();
      #{Generator.kernel_name(nif_name)}_i64(vec_long, vec_l);
      uint64_t end_time = now();
      free(vec_long);
      return end_time - start_time;
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

      printf("#{Generator.kernel_name(nif_name)}_double: r = %lf, a = %lf, b = %lf\\n", result_double[0], result_double[1], result_double[2]);
      printf("#{Generator.kernel_name(nif_name)}_i64: r = %lf, a = %lf, b = %lf\\n", result_i64[0], result_i64[1], result_i64[2]);

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

  def chunk_every(info) do
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
  def sort(info) do
    Util.push_impl_info(info, false, false)

    nil
  end

  def filter(info) do
    Util.push_impl_info(info, false, false)

    nil
  end
end
