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
  end
end
```

## Supported Platforms

Potentially, Pelemay may support any architectures that both Erlang and Clang are supported.

We've tested it well on the following processor architectures:

* x86_64

We've tested it well on the following OS:

* macOS (64bit)
* Linux (64bit)
* Windows (64bit)

We've tested it on the following Elixir versions:

* 1.9

We've tested it on the following OTP versions:

* 22
* 21
* 20

We've tested it on Clang 6 or later.
Potentially, Clang that supports auto-vectorization may support Pelemay.

We heard the reports that it works on the following systems:

* RasPi 4, 32bit Raspbian, Elixir 1.7.4 (with warning)

## Pre-installation

Pelemay requires Clang that supports auto-vectorization.

## Installation

Add `pelemay` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pelemay, "~> 0.0"},
  ]
end
```

Documentation is generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). The docs will
be found at [https://hexdocs.pm/pelemay](https://hexdocs.pm/pelemay).
