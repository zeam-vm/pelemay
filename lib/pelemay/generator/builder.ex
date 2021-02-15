defmodule Pelemay.Generator.Builder do
  alias Pelemay.Generator
  require Logger

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

  def depend(string, cc) when is_binary(string) do
    cmd(
      cc,
      ["-MM", "-I#{erlang_include_path()}", "-I#{__DIR__}/native", string],
      Generator.build_dir(),
      %{}
    )
  end

  def depend(module, cc), do: depend(Generator.libc(module), cc)

  def generate_makefile("", _, _, _) do
    {:error, "Don't need defpelemay"}
  end

  def generate_makefile(_module, "nmake", _, _) do
    {:error, "Pelemay for Windows haven't been implemented, yet."}
  end

  def generate_makefile(module, _, cc, env) do
    kernels = Pelemay.Db.get_kernels()

    kernel_cs =
      kernels
      |> Enum.map(&"#{Generator.src_dir()}/#{Generator.kernel_name(&1)}.c")

    kernel_dcs =
      kernels
      |> Enum.map(&"#{Generator.src_dir()}/#{Generator.kernel_driver_name(&1)}.c")

    kernel_bcs =
      kernels
      |> Enum.map(&"#{Generator.src_dir()}/#{Generator.kernel_name(&1)}_base.c")

    kernel_dbcs =
      kernels
      |> Enum.map(&"#{Generator.src_dir()}/#{Generator.kernel_driver_name(&1)}_base.c")

    kernel_os =
      kernels
      |> Enum.map(&"#{Generator.kernel_name(&1)}.o")

    kernel_dos =
      kernels
      |> Enum.map(&"#{Generator.kernel_driver_name(&1)}.o")

    kernel_bos =
      kernels
      |> Enum.map(&"#{Generator.kernel_name(&1)}_base.o")

    kernel_dbos =
      kernels
      |> Enum.map(&"#{Generator.kernel_driver_name(&1)}_base.o")

    kernel_bench =
      kernels
      |> Enum.map(&"#{Generator.kernel_name(&1)}_bench")

    kernel_perf =
      kernels
      |> Enum.map(&"#{Generator.kernel_name(&1)}_perf")

    kernel_bench_cs =
      kernels
      |> Enum.map(&"#{Generator.src_dir()}/#{Generator.kernel_name(&1)}_bench.c")

    kernel_perf_cs =
      kernels
      |> Enum.map(&"#{Generator.src_dir()}/#{Generator.kernel_name(&1)}_perf.c")

    flags =
      env
      |> Enum.map(fn {key, value} -> "#{key} = #{value}" end)
      |> Enum.join("\n")

    bench_dep =
      Enum.zip([kernel_bench, kernel_bos, kernel_dbos])
      |> Enum.map(fn {kb, kbo, kbdo} ->
        """
        ../priv/#{kb}: ../obj/#{kb}.o ../obj/#{kbo} ../obj/#{kbdo} ../obj/lsm_base.o
        \t$(CC) $^ -o $@ $(LDFLAGS)

        """
      end)

    perf_dep =
      Enum.zip([kernel_perf, kernel_bos, kernel_dbos])
      |> Enum.map(fn {kp, kbo, kbdo} ->
        """
        ../priv/#{kp}: ../obj/#{kp}.o ../obj/#{kbo} ../obj/#{kbdo}
        \t$(CC) $^ -o $@ $(LDFLAGS)

        """
      end)

    str = """
    .phony: all clean

    #{flags}

    LINK = 

    CFLAGS += -Ofast -g -ansi -pedantic -I#{__DIR__}/native
    ifdef CROSSCOMPILE
      CFLAGS += $(ERL_CFLAGS)
      LDFLAGS += $(ERL_LDFLAGS)
    else
      CFLAGS += -I#{erlang_include_path()}
    endif
    CFLAGS += -std=c11 -Wno-unused-function

    TARGET_BENCH_PERF = \\
    #{kernel_bench |> Enum.map(&"  ../priv/#{&1}") |> Enum.join(" \\\n")} \\
    #{kernel_perf |> Enum.map(&"  ../priv/#{&1}") |> Enum.join(" \\\n")}

    ifeq ($(OS), Windows_NT)
      TARGET_LIB = ../priv/#{Generator.libnif_name(module)}.dll
        
    else
      TARGET_LIB = ../priv/#{Generator.libnif_name(module)}.so

      CFLAGS += -fPIC
      ifeq ($(shell uname),Darwin)
        ifndef CROSSCOMPILE
          CFLAGS += -I`xcrun --show-sdk-path 2>/dev/null`/usr/include
          LDFLAGS += -L`xcrun --show-sdk-path 2>/dev/null`/usr/lib
          LINK += -dynamiclib -undefined dynamic_lookup
        endif
      endif
    endif


    OBJS = ../obj/#{Generator.libnif_name(module)}.o \\
    #{(kernel_os ++ kernel_dos) |> Enum.map(&"  ../obj/#{&1}") |> Enum.join(" \\\n")} \\
      ../obj/basic.o \\
      ../obj/lsm.o

    all: $(TARGET_LIB) $(TARGET_BENCH_PERF)
    \t

    $(TARGET_LIB): $(OBJS)
    \t$(CC) $^ -o $@ -shared $(LDFLAGS) $(LINK)

    #{bench_dep}

    #{perf_dep}

    include $(shell ls *.d 2>/dev/null)

    %.o %.c:
    \t$(CC) -S $< -o $*.s $(CFLAGS)
    \t$(CC) -c $< -o $@ $(CFLAGS)

    clean:
    \t$(RM) $(TARGET) $(OBJS)
    """

    File.write(Generator.makefile(module), str)

    deps_kernels =
      (kernel_cs ++
         kernel_dcs ++
         kernel_bcs ++
         kernel_dbcs ++
         kernel_bench_cs ++
         kernel_perf_cs)
      |> Enum.map(&depend(&1, cc))

    status_kernels = Enum.reduce(deps_kernels, 0, fn {_, status}, acc -> status + acc end)

    if deps_kernels |> Enum.filter(fn {r, _} -> String.match?(r, ~r/error:/) end) != [] do
      raise "Build error."
    end

    if status_kernels == 0 do
      File.write(
        "#{Generator.build_dir()}/kernels.d",
        deps_kernels
        |> Enum.map(fn {result, _} -> "../obj/#{result}" end)
        |> Enum.join("\n")
      )
    end

    case depend(module, cc) do
      {deps, 0} ->
        File.write(
          "#{Generator.build_dir()}/#{Generator.libnif_name(module)}.d",
          "../obj/#{deps}"
        )

      _ ->
        raise "Build error."
    end

    case depend("#{__DIR__}/native/basic.c", cc) do
      {deps_basic, 0} ->
        File.write(
          "#{Generator.build_dir()}/basic.d",
          "../obj/#{deps_basic}"
        )

      _ ->
        raise "Build error."
    end

    case depend("#{__DIR__}/native/lsm.c", cc) do
      {deps_lsm, 0} ->
        File.write(
          "#{Generator.build_dir()}/lsm.d",
          "../obj/#{deps_lsm}"
        )

      _ ->
        raise "Build error."
    end

    case depend("#{__DIR__}/native/lsm_base.c", cc) do
      {deps_lsm_base, 0} ->
        File.write(
          "#{Generator.build_dir()}/lsm_base.d",
          "../obj/#{deps_lsm_base}"
        )

      _ ->
        raise "Build error."
    end
  end

  def generate(module) do
    # copy_c_src()

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

    erl_ei_include_dir = System.get_env("ERL_EI_INCLUDE_DIR") || ""
    erl_ei_libdir = System.get_env("ERL_EI_LIBDIR") || ""

    crosscompile = System.get_env("CROSSCOMPILE")

    env =
      %{
        "CC" => cc,
        "CFLAGS" => cflags |> Enum.join(" "),
        "LDFLAGS" => ldflags |> Enum.join(" "),
        "ERL_CFLAGS" => erl_cflags,
        "ERL_LDFLAGS" => erl_ldflags,
        "ERL_EI_INCLUDE_DIR" => erl_ei_include_dir,
        "ERL_EI_LIBDIR" => erl_ei_libdir
      }
      |> Map.merge(
        if is_nil(crosscompile) do
          %{}
        else
          %{"CROSSCOMPILE" => crosscompile}
        end
      )

    generate_makefile(module, os_specific_make(), cc, env)

    {result, status} =
      make(
        args_for_makefile(
          os_specific_make(),
          Generator.makefile(module),
          Map.get(cpu_info, :cpu) |> Map.get(:total_num_of_threads)
        ),
        env
      )

    if status != 0 do
      Logger.error(result)
      raise "Build failed."
    end
  end

  def erlang_include_path() do
    "#{:code.root_dir()}/erts-#{:erlang.system_info(:version)}/include"
  end

  def make(args, env) do
    case cmd(
           os_specific_make(),
           args,
           Generator.build_dir(),
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
    end
  end

  def args_for_makefile("nmake", :default, _cpu_threads), do: ["/F", "Makefile.win"]
  def args_for_makefile("nmake", makefile, _cpu_threads), do: ["/F", makefile]

  def args_for_makefile(_, :default, cpu_threads) do
    ["-j", Integer.to_string(cpu_threads)]
  end

  def args_for_makefile(_, makefile, cpu_threads) do
    ["-f", makefile, "-j", Integer.to_string(cpu_threads)]
  end
end
