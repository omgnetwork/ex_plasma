# ExPlasma

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_plasma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_plasma, "~> 0.1.0"}
  ]
end
```

### Quick Start


Most of the tests should have `exvcr` coverage, but for those that don't and need a live service, that's
where docker comes in:

```sh
docker-compose up
```


Then run the tests. Optionally, with `iex` to pry into the code

```sh
iex -S mix test
```

### Demoing

#### Start up the Service

First, start up the ethereum client and load up the contracts. You can do this by using `docker-compose`:

```sh
docker-compose up
```

##### Depositing Eth into contract

```elixir
contract = "0x1967d06b1faba91eaadb1be33b277447ea24fa0e"
alice = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
currency = ExPlasma.Encoding.to_hex(<<0::160>>)
metadata = ExPlasma.Encoding.to_hex(<<0::256>>)
deposit = Deposit.new(alice, currency, 1, metadata)
deposit
|> Transaction.encode()
|> Client.deposit(alice, contract, 1)
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_plasma](https://hexdocs.pm/ex_plasma).

