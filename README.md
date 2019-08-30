# Hastega

**Hastega: Hyper Accelerator of Spreading Tasks for Elixir with GPU Activation**

For example, the following code of the function `map_square` will be compiled to native code using SIMD instructions by Hastega.

```elixir
defmodule M do
  require Hastega
  import Hastega

  defhastega do
    def map_square (list) do
      list
      |> Enum.map(& &1 * &1)
    end

    hastegastub
  end
end
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hastega` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hastega, "~> 0.0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hastega](https://hexdocs.pm/hastega).

