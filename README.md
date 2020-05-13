[![Coverage Status](https://coveralls.io/repos/github/omisego/ex_plasma/badge.svg?branch=master)](https://coveralls.io/github/omisego/ex_plasma?branch=master)

# ExPlasma

**TODO: Add description**

(ExPlasma)[] is an elixir client library to interact with the OmiseGO Plasma contracts.

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

You will also need to specify some configurations in your [config/config.exs]():

```elixir
config :ex_plasma,
  eip_712_domain: %{
    name: "ExPlasma",
    salt: "some-salt",
    verifying_contract: "contract_address",
    version: "1"
  }
```

## Setup (Mac OS)

1. Clone the repo to your desktop `git@github.com:omisego/ex_plasma.git`
2. Run `mix compile` in your terminal.
3. If there are any unavailable dependencies, run `mix deps.get`.
*If you run into any issues with* ***libsecp256k1_source***, *run* `brew install automake pkg-config libtool libffi gmp` *in your terminal.* 

## Testing


You can run the tests by running;

```sh
mix test
mix credo
mix dialyzer
```

### exvcr

The test suite has network requests recorded by [exvcr](). To record new cassettes, spin up docker:

```sh
docker-compose up
```

Or alternatively, you can use the make command to spin up a detached docker compose.

```sh
make up # docker-compose detached
make logs # connects to logs from docker-compose
```

This will load up Ganche and the plasma contracts to deploy.


### Conformance test

To ensure we can encode/decode according to the contracts, we have a separate suite of conformance tests that
loads up mock contracts to compare encoding results. You can run the test by:

```sh
make up-mocks
mix test --only conformance
```

This will spin up ganache and deploy the mock contracts.

### Integration test

We also have more integrated flows we need to test, such as the exit game. These use live interactions with
the plasma framework contracts. To run those, you can execute:

```sh
make up
mix test --only integration
```

This will spin up ganache and deploy the plasma framework and run the integration suite.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_plasma](https://hexdocs.pm/ex_plasma).
