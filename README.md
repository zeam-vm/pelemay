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
* Windows

We've tested it on the following Elixir versions:

* 1.9

We've tested it on the following OTP versions:

* 22
* 21
* 20

## Installation

We recommend using Pelemay got from the master branch of GitHub directly for the present, because of current unstable development.

Add `pelemay` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pelemay, "~> 0.0", branch: "master"},
  ]
end
```

Documentation is generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). The docs will
be found at [https://hexdocs.pm/pelemay](https://hexdocs.pm/pelemay).
