defmodule Pelemay.Generator.Builder do
  alias Pelemay.Generator

  @clang "clang"
  @gcc "gcc"
  @cflags ["-Ofast", "-g", "-ansi", "-pedantic"]
  @cflags_includes ["-I/usr/local/include", "-I/usr/include"]
  @cflags_after ["-std=c11", "-Wno-unused-function"]
  @ldflags ["-L/usr/local/lib", "-L/usr/lib"]
  @cflags_non_windows ["-fPIC"]
  @ldflags_non_windows ["-dynamiclib", "-undefined", "dynamic_lookup"]

  def generate(module) do
    cc = System.get_env("CC")

    cc =
      if is_nil(cc) or is_nil(System.find_executable(cc)) do
        @clang
      else
        cc
      end

    cc =
      if is_nil(System.find_executable(cc)) do
        @gcc
      else
        cc
      end

    if is_nil(System.find_executable(cc)) do
      raise CompileError, message: "#{cc} is not installed."
    end

    {cflags_t, ldflags_t} =
      if is_nil(System.get_env("CROSSCOMPILE")) do
        {
          @cflags ++ ["-I#{erlang_include_path()}"] ++ @cflags_includes ++ @cflags_after,
          @ldflags
        }
      else
        {
          String.split(System.get_env("CFLAGS")) ++ String.split(System.get_env("ERL_CFLAGS")),
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
