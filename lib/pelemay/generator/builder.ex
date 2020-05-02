defmodule Pelemay.Generator.Builder do
  alias Pelemay.Generator

  @mac_error_msg """
  You need to have gcc and make installed. Try running the
  commands "gcc --version" and / or "make --version". If these programs
  are not installed, you will be prompted to install them.
  """

  @unix_error_msg """
  You need to have gcc and make installed. If you are using
  Ubuntu or any other Debian-based system, install the packages
  "build-essential". Also install "erlang-dev" package if not
  included in your Erlang/OTP version. If you're on Fedora, run
  "dnf group install 'Development Tools'".
  """

  @windows_error_msg ~S"""
  One option is to install a recent version of
  [Visual C++ Build Tools](http://landinghub.visualstudio.com/visual-cpp-build-tools)
  either manually or using [Chocolatey](https://chocolatey.org/) -
  `choco install VisualCppBuildTools`.
  After installing Visual C++ Build Tools, look in the "Program Files (x86)"
  directory and search for "Microsoft Visual Studio". Note down the full path
  of the folder with the highest version number. Open the "run" command and
  type in the following command (make sure that the path and version number
  are correct):
      cmd /K "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
  This should open up a command prompt with the necessary environment variables
  set, and from which you will be able to run the "mix compile", "mix deps.compile",
  and "mix test" commands.
  """

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

  def depend(module, cc) do
    cmd(
      cc,
      ["-MM", "-I#{erlang_include_path()}", Generator.libc(module)],
      Application.app_dir(:pelemay, "priv"),
      %{}
    )
  end

  def generate_makefile("", _, _) do
    {:error, "Don't need defpelemay"}
  end

  def generate_makefile(_module, "nmake", _) do
    {:error, "Pelemay for Windows haven't been implemented, yet."}
  end

  def generate_makefile(module, _, cc) do
    {deps, status} = depend(module, cc)

    if status == 0 do
      str = """
      .phony: all clean

      CFLAGS += -Ofast -g -ansi -pedantic
      ifdef CROSSCOMPILE
        CFLAGS += $(ERL_CFLAGS)
        LDFLAGS += $(ERL_LDFLAGS)
      else
        CFLAGS += -I#{erlang_include_path()}
      endif
      CFLAGS += -std=c11 -Wno-unused-function

      ifeq ($(OS), Windows_NT)
        TARGET=#{Generator.libnif_name(module)}.dll
      else
        TARGET =#{Generator.libnif_name(module)}.so
        CFLAGS += -fPIC
        ifeq ($(shell uname),Darwin)
          ifndef CROSSCOMPILE
            LDFLAGS += -dynamiclib -undefined dynamic_lookup
          endif
        endif
      endif

      OBJS=#{Generator.libnif_name(module)}.o

      $(TARGET): $(OBJS)
      \t$(CC) $^ -o $@ -shared $(LDFLAGS)

      #{deps}

      %.o %.c:
      \t$(CC) -c $< -o $@ $(CFLAGS)

      clean:
      \trm $(TARGET) $(OBJS)
      """

      File.write(Generator.makefile(module), str)
    end
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

    ldflags = cpu_info |> Map.get(:compiler) |> Map.get(:ldflags_env) |> String.split()

    erl_cflags = System.get_env("ERL_CFLAGS") || ""
    erl_ldflags = System.get_env("ERL_LDFLAGS") || ""

    crosscompile = System.get_env("CROSSCOMPILE")

    env =
      %{
        "CC" => cc,
        "CFLAGS" => cflags |> Enum.join(" "),
        "LDFLAGS" => ldflags |> Enum.join(" "),
        "ERL_CFLAGS" => erl_cflags,
        "ERL_LDFLAGS" => erl_ldflags
      }
      |> Map.merge(
        if is_nil(crosscompile) do
          %{}
        else
          %{"CROSSCOMPILE" => crosscompile}
        end
      )

    generate_makefile(module, os_specific_make(), cc)

    {_result, 0} =
      make(
        args_for_makefile(os_specific_make(), Generator.makefile(module)),
        env
      )
  end

  def erlang_include_path() do
    "#{:code.root_dir()}/erts-#{:erlang.system_info(:version)}/include"
  end

  def make(args, env) do
    case cmd(
           os_specific_make(),
           args,
           Application.app_dir(:pelemay, "priv"),
           env
         ) do
      {_, :enoent} -> {os_specific_error_msg(), :enoent}
      {result, status} -> {result, status}
    end
  end

  def cmd(exec, args, cwd, env) do
    opts = [
      stderr_to_stdout: true,
      cd: cwd,
      env: env
    ]

    if is_nil(System.find_executable(exec)) do
      {"", :enoent}
    else
      System.cmd(exec, args, opts)
    end
  end

  def os_specific_make() do
    case :os.type() do
      {:win32, _} -> "nmake"
      {:unix, type} when type in [:freebsd, :openbsd] -> "gmake"
      _ -> "make"
    end
  end

  def os_specific_error_msg() do
    case :os.type() do
      {:unix, :darwin} -> @mac_error_msg
      {:unix, _} -> @unix_error_msg
      {:win32, _} -> @windows_error_msg
      _ -> ""
    end
  end

  def args_for_makefile("nmake", :default), do: ["/F", "Makefile.win"]
  def args_for_makefile("nmake", makefile), do: ["/F", makefile]
  def args_for_makefile(_, :default), do: []
  def args_for_makefile(_, makefile), do: ["-f", makefile]
end
