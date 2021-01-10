defmodule Pelemay.Generator.Native do
  alias Pelemay.Db
  alias Pelemay.Generator
  alias Pelemay.Generator.Native.Util, as: Util

  require Logger

  def generate(module) do
    code_info = Db.get_functions()
    Db.clear()

    Pelemay.Generator.libc(module) |> write(module, code_info)

    Pelemay.Generator.libh(module) |> write_h(module, code_info)
  end

  defp write(file, module, code_info) do
    str =
      init_nif(module)
      |> generate_functions(module, code_info)
      |> init_priv_data(module)
      |> erl_nif_init(module)

    file |> File.write(str)
  end

  defp generate_functions(str, module, code_info) do
    definition_func =
      code_info
      |> Enum.map(&generate_function(module, &1))
      |> Enum.filter(&(!is_nil(&1)))
      |> Enum.map(&(&1 <> "\n"))

    str <> Util.to_str_code(definition_func) <> func_list()
  end

  defp generate_function(module, [func_info]) do
    generate_function(module, func_info)
  end

  defp generate_function(module, %{module: modules, function: funcs, nif_name: nif_name} = info) do
    object_module = Enum.reduce(modules, "", fn module, acc -> acc <> Atom.to_string(module) end)

    [hd | tl] = funcs

    acc =
      hd
      |> Keyword.keys()
      |> Enum.map(&Atom.to_string(&1))
      |> List.to_string()

    object_func =
      Enum.reduce(tl, acc, fn [{func, _}], acc -> acc <> "_" <> Atom.to_string(func) end)

    prefix = "Pelemay.Generator.Native.#{object_module}.#{object_func}"

    {res, _} =
      try do
        Code.eval_string("#{prefix}(module, info)", module: module, info: info)
      rescue
        e in UndefinedFunctionError ->
          Util.push_info(info, :impl, false)
          error(e)
      end

    init_resource_type =
      if is_nil(res) do
        ""
      else
        """

        static ErlNifResourceType *
        init_resource_type_#{nif_name}(ErlNifEnv *env)
        {
          ErlNifResourceFlags tried;
          ErlNifResourceType *ret = enif_open_resource_type(
            env,
            NULL, // module_str (unused, must be NULL)
            "#{Pelemay.Generator.resource_state(nif_name)}",
            NULL, // No descructor
            ERL_NIF_RT_CREATE,
            &tried
          );
          return ret;
        }

        """
      end

    res =
      if is_nil(res) do
        ""
      else
        res
      end

    res <> init_resource_type
  end

  defp func_list do
    fl =
      Db.get_functions()
      |> Enum.reduce(
        "",
        fn
          [%{impl: true, impl_drv: true}] = info, acc ->
            acc <>
              """
                #{erl_nif_func(info)},
                #{erl_nif_driver_double_func(info)},
                #{erl_nif_driver_i64_func(info)},
                #{erl_nif_driver_lsm_double_func(info)},
                #{erl_nif_driver_lsm_i64_func(info)},
              """

          [%{impl: true, impl_drv: false}] = info, acc ->
            acc <>
              """
                #{erl_nif_func(info)},
              """

          [%{impl: false}], acc ->
            acc
        end
      )

    """
    static
    ErlNifFunc nif_funcs[] =
    {
      // {erl_function_name, erl_function_arity, c_function}
    #{fl}
    };

    """
  end

  defp init_priv_data(str, module) do
    fl =
      Db.get_functions()
      |> Enum.reduce(
        "",
        fn
          [%{impl: true, nif_name: nif_name}], acc ->
            acc <>
              """
                data->#{Pelemay.Generator.resource_state(nif_name)} = init_resource_type_#{
                nif_name
              }(env);
                if(data->#{Pelemay.Generator.resource_state(nif_name)} == NULL) {
                  enif_free(data);
                  return NULL;
                }
              """

          [%{impl: false}], acc ->
            acc
        end
      )

    str <>
      """
      static
      struct #{Pelemay.Generator.priv_data(module)}* init_priv_data(ErlNifEnv *env)
      {
        struct #{Pelemay.Generator.priv_data(module)} *data = enif_alloc(sizeof(struct #{
        Pelemay.Generator.priv_data(module)
      }));
      #{fl}
        return data;
      }
      """
  end

  defp write_h(file, module, _code_info) do
    str = "// header file for #{module}\n"

    fl =
      Db.get_functions()
      |> Enum.reduce(
        "",
        fn
          [%{impl: true, nif_name: nif_name}], acc ->
            acc <>
              """
                ErlNifResourceType *#{Pelemay.Generator.resource_state(nif_name)};
              """

          [%{impl: false}], acc ->
            acc
        end
      )

    str =
      str <>
        """
        struct #{Pelemay.Generator.priv_data(module)} {
        #{fl}
        };
        """

    file |> File.write(str)
  end

  defp erl_nif_func([%{nif_name: nif_name, arg_num: num}]) do
    ~s/{"#{nif_name}_nif", #{num}, #{nif_name}_nif}/
  end

  defp erl_nif_driver_double_func([%{nif_name: nif_name}]) do
    ~s/{"#{nif_name}_nif_driver_double", 1, #{nif_name}_nif_driver_double}/
  end

  defp erl_nif_driver_i64_func([%{nif_name: nif_name}]) do
    ~s/{"#{nif_name}_nif_driver_i64", 1, #{nif_name}_nif_driver_i64}/
  end

  defp erl_nif_driver_lsm_double_func([%{nif_name: nif_name}]) do
    ~s/{"#{nif_name}_nif_driver_lsm_double", 0, #{nif_name}_nif_driver_lsm_double}/
  end

  defp erl_nif_driver_lsm_i64_func([%{nif_name: nif_name}]) do
    ~s/{"#{nif_name}_nif_driver_lsm_i64", 0, #{nif_name}_nif_driver_lsm_i64}/
  end

  defp init_nif(module) do
    """
    // This file was generated by Pelemay.Generator.Native
    #pragma clang diagnostic ignored "-Wnullability-completeness"
    #pragma clang diagnostic ignored "-Wnullability-extension"

    #include <stdbool.h>
    #include <erl_nif.h>
    #include <string.h>
    #include <basic.h>
    #include <lsm.h>
    #include "#{Pelemay.Generator.libh_name(module)}"

    inline int min(int const x, int const y)
    {
      return y < x ? y : x;
    }

    static struct #{Pelemay.Generator.priv_data(module)} *init_priv_data(ErlNifEnv *env);
    static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info);
    static void unload(ErlNifEnv *env, void *priv);
    static int reload(ErlNifEnv *env, void **priv, ERL_NIF_TERM info);
    static int upgrade(ErlNifEnv *env, void **priv, void **old_priv, ERL_NIF_TERM info);

    static int
    load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
    {
      atom_struct = enif_make_atom(env, "__struct__");
      atom_range = enif_make_atom(env, "Elixir.Range");
      atom_first = enif_make_atom(env, "first");
      atom_last = enif_make_atom(env, "last");
      *priv = init_priv_data(env);
      return 0;
    }

    static void
    unload(ErlNifEnv *env, void *priv)
    {
    }

    static int
    reload(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
    {
      return 0;
    }

    static int
    upgrade(ErlNifEnv *env, void **priv, void **old_priv, ERL_NIF_TERM info)
    {
      return load(env, priv, info);
    }

    """
  end

  defp erl_nif_init(str, module) do
    str <>
      """
      ERL_NIF_INIT(Elixir.#{Generator.nif_module(module)}, nif_funcs, &load, &reload, &upgrade, &unload)
      """
  end

  defp error(e) do
    Logger.warn(
      "Please write a native code of the following code: #{e.module}.#{e.function}/#{e.arity}"
    )

    {nil, []}
  end
end
