# Nerves_Hcsr04

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hcsr04` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nerves_hcsr04, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
{:ok, pid} = Hcsr04.start_link([trigger: 18, echo: 24])
distance_in_mm = Hcsr04.read(pid)
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hcsr04](https://hexdocs.pm/hcsr04).
