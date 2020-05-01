defmodule Pelemay.Generator.Builder do
  alias Pelemay.Generator

  @cflags ["-Ofast", "-g", "-ansi", "-pedantic"]
  @cflags_includes ["-I/usr/local/include", "-I/usr/include"]
  @cflags_after ["-std=c11", "-Wno-unused-function"]
  @ldflags ["-L/usr/local/lib", "-L/usr/lib"]
  @cflags_non_windows ["-fPIC"]
  @ldflags_non_windows ["-dynamiclib", "-undefined", "dynamic_lookup"]

  def parse_info(compile_time_info) do
    Map.get(compile_time_info, :compiler) |> parse_compiler()
  end

  defp parse_compiler(compiler) do
    parse_compiler_sub(Map.get(compiler, :cc_env), compiler)
  end

  def apple_clang(compiler) do
    Map.get(compiler, :apple_clang)
  end

  def clang(compiler) do
    Map.get(compiler, :clang)
    |> Enum.filter(&(Map.get(&1, :type) == :clang))
  end

  def gcc(compiler) do
    Map.get(compiler, :gcc)
    |> Enum.filter(&(Map.get(&1, :type) == :gcc))
  end

  defp parse_compiler_sub([], compiler) do
    case {apple_clang(compiler), clang(compiler), gcc(compiler)} do
      {nil, [], []} -> []
      {nil, [], gcc} -> gcc
      {nil, clang, _} -> clang
      {apple_clang, _, _} -> apple_clang
    end
  end

  defp parse_compiler_sub(cc, _compiler) do
    cc
  end

  def select_latest(cc) do
    Enum.reduce(cc, fn x, acc ->
      if Map.get(x, :version) >= Map.get(acc, :version) do
        x
      else
        acc
      end
    end)
  end

  def generate(module) do
    cpu_info =
      Pelemay.eval_compile_time_info()
      |> elem(0)

    cc =
      cpu_info
      |> parse_info()
      |> select_latest()
      |> Map.get(:bin)

    if is_nil(System.find_executable(cc)) do
      raise CompileError, message: "#{cc} is not installed."
    end

    cflags = cpu_info |> Map.get(:compiler) |> Map.get(:cflags_env) |> String.split()

    {cflags_t, ldflags_t} =
      if is_nil(System.get_env("CROSSCOMPILE")) do
        {
          cflags ++
            @cflags ++ ["-I#{erlang_include_path()}"] ++ @cflags_includes ++ @cflags_after,
          @ldflags
        }
      else
        {
          cflags ++ String.split(System.get_env("ERL_CFLAGS")),
          @ldflags ++ String.split(System.get_env("ERL_LDFLAGS"))
        }
      end

    cflags =
      case :os.type() do
        {:win32, :nt} -> cflags_t
        _ -> cflags_t ++ @cflags_non_windows
      end

    ldflags =
      case :os.type() do
        {:win32, :nt} ->
          ldflags_t

        {:unix, :darwin} ->
          if is_nil(System.get_env("CROSSCOMPILE")) do
            ldflags_t ++ @ldflags_non_windows
          else
            ldflags_t
          end

        _ ->
          ldflags_t
      end

    options =
      cflags ++ ["-shared"] ++ ldflags ++ ["-o", Generator.libso(module), Generator.libc(module)]

    {_result, 0} = System.cmd(cc, options)
  end

  def erlang_include_path() do
    "#{:code.root_dir()}/erts-#{:erlang.system_info(:version)}/include"
  end
end
