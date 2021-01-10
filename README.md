# Pelemay
**Pelemay = The Penta (Five) “Elemental Way”: Freedom, Insight, Beauty, Efficiency and Robustness**

For example, the following code of the function `map_square` will be compiled to native code using SIMD instructions by Pelemay.

```elixir
defmodule M do
  require Pelemay
  import Pelemay

  defpelemay do
    def map_square (list) do
      list
      |> Enum.map(& &1 * &1)
    end

    def string_replace(list) do
      list
      |> Enum.map(& String.replace(&1, "Fizz", "Buzz"))
    end
  end
end
```

## Supported Platforms

Potentially, Pelemay may support any architectures that both Erlang and Clang or GCC are supported.

We've tested it well on the following processor architectures:

* x86_64
* ARM

We've tested it well on the following OS:

* macOS (64bit, including Apple Silicon M1 Mac on ARM native mode (unfortunately, not works on Rosetta 2))
* Linux (64bit)
* Nerves (Raspberry Pi 3)

I'm so sorry but Windows isn't be supported because of changing the builder of Pelemay.

We've tested it on the following Elixir versions:

* 1.9
* 1.11

We've tested it on the following OTP versions:

* 23
* 22
* 21
* 20

We've tested it on Clang 6 or later and GCC 7 or later.
Potentially, Clang and GCC that supports auto-vectorization can generate native code with SIMD instructions by Pelemay.

Pelemay also supports Nerves.

## Pre-installation

Pelemay requires Clang or GCC and make.

Environment Variable `CC` is recommended being set the path of the C compiler you want to use.

## Installation

Add `pelemay` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pelemay, "~> 0.0.15"},
  ]
end
```

Documentation is generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). The docs will
be found at [https://hexdocs.pm/pelemay](https://hexdocs.pm/pelemay).
