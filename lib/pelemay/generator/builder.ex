defmodule Pelemay.Generator.Builder do
  alias Pelemay.Generator

  @clang "clang"
  @gcc "gcc"
  @cflags ["-Ofast", "-g", "-ansi", "-pedantic"]
  @cflags_includes ["-I/usr/local/include", "-I/usr/include", "-L/usr/local/lib", "-L/usr/lib"]
  @cflags_after ["-std=c11", "-Wno-unused-function"]
  @ldflags []
  @cflags_non_windows ["-fPIC"]
  @ldflags_non_windows ["-dynamiclib", "-undefined", "dynamic_lookup"]

  def generate(module) do
    cc = System.get_env("CC")

    cc =
      if is_nil(System.find_executable(cc)) do
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

    cflags_t = @cflags ++ ["-I#{erlang_include_path()}"] ++ @cflags_includes ++ @cflags_after
    ldflags_t = @ldflags

    cflags =
      case :os.type() do
        {:win32, :nt} -> cflags_t
        _ -> cflags_t ++ @cflags_non_windows
      end

    ldflags =
      case :os.type() do
        {:win32, :nt} -> ldflags_t
        {:unix, :darwin} -> ldflags_t
        _ -> ldflags_t ++ @ldflags_non_windows
      end

    options =
      cflags ++ ["-shared"] ++ ldflags ++ ["-o", Generator.libso(module), Generator.libc(module)]

    {_result, 0} = System.cmd(cc, options)
  end

  def erlang_include_path() do
    "#{:code.root_dir()}/erts-#{:erlang.system_info(:version)}/include"
  end
end
