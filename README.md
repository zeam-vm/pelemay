[![CircleCI](https://circleci.com/gh/zeam-vm/pelemay/tree/master.svg?style=svg)](https://circleci.com/gh/zeam-vm/pelemay/tree/master)
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

We've tested it on the following OS:

* macOS
* Linux

We've NOT tested it on the following OS (your help is nedded):

* Windows (including WSL, cygwin, etc.)

We've tested it on the following Elixir versions:

* 1.9

We've tested it on the following OTP versions:

* 22
* 21
* 20

## Installation

Add `pelemay` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pelemay, "~> 0.0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pelemay](https://hexdocs.pm/pelemay).
