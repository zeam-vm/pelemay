# Pelemay
**Pelemay = The Penta (Five) “Elemental Way”: Freedom, Insight, Beauty, Efficiency and Robustness**

For example, the following code of the function `map_square` will be compiled to native code using SIMD instructions by Pelemay.

```elixir
defmodule M do
  require Pelemay
  import Pelemay

  defhastega do
    def map_square (list) do
      list
      |> Enum.map(& &1 * &1)
    end
  end
end
```


## Installation

Add `pelemay` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pelemay, "~> 0.0.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hastega](https://hexdocs.pm/pelemay).

