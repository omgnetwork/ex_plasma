[![Build Status](https://circleci.com/gh/omgnetwork/ex_plasma.svg?style=svg)](https://circleci.com/gh/omgnetwork/ex_plasma)

# ExPlasma

ExPlasma is an Elixir library for encoding, decoding and validating transactions used for the OMG Network Plasma contracts.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_plasma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_plasma, "~> 0.2.0"}
  ]
end
```

You will also need to specify some configurations in your [config/config.exs]():

```elixir
config :ex_plasma,
  eip_712_domain: %{
    name: "OMG Network",
    salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
    verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
    version: "1"
  }
```

## Setup

1. Cloneр the repo to your desktop `git@github.com:omgnetwork/ex_plasma.git`
2. Run `mix compile` in your terminal.
3. If there are any unavailable dependencies, run `mix deps.get`.


*If you run into any issues with* ***libsecp256k1_source***, *run in your terminal:*

Mac OS: `brew install automake pkg-config libtool libffi gmp`
Debian/Ubuntu: `apt-get -y install autoconf build-essential libgmp3-dev libtool`

## Usage


View the [documentation](https://hexdocs.pm/ex_plasma)

## Testing

You can run the tests by running;

```sh
mix test
mix credo
mix dialyzer
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

## Contributing

1. [Fork it!](https://github.com/omgnetwork/ex_plasma)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

ExPlasma is released under the Apache-2.0 License.
