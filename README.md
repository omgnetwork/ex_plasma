## ExPlasma
[![Build Status](https://circleci.com/gh/omgnetwork/ex_plasma.svg?style=svg)](https://circleci.com/gh/omgnetwork/ex_plasma)

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

1. Clone the repo to your desktop `git@github.com:omgnetwork/ex_plasma.git`
2. Run `mix compile` in your terminal.
3. If there are any unavailable dependencies, run `mix deps.get`.


*If you run into any issues with* ***libsecp256k1_source***, *run in your terminal:*

Mac OS: `brew install automake pkg-config libtool libffi gmp`
Debian/Ubuntu: `apt-get -y install autoconf build-essential libgmp3-dev libtool`

## Usage

You can encode a transaction using `ExPlasma.encode/2`:

``` elixir
txn =
 %ExPlasma.Transaction{
   inputs: [
     %ExPlasma.Output{
       output_data: nil,
       output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
       output_type: nil
     }
   ],
   metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
   outputs: [
     %ExPlasma.Output{
       output_data: %{
         amount: 1,
         output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153,
           217, 206, 65, 226, 241, 55, 0, 110>>,
         token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206,
           65, 226, 241, 55, 0, 110>>
       },
       output_id: nil,
       output_type: 1
     }
   ],
   sigs: [],
   tx_data: 0,
   tx_type: 1
}

ExPlasma.encode(txn, signed: false)
{:ok, <<248, 116, 1, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 237, 1, 235, 148, 29, 246, 47,
41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110,
148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
241, 55, 0, 110, 1, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}
```

You can decode a transaction using `ExPlasma.decode/2`:

``` elixir
rlp = <<248, 116, 1, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 237, 1, 235, 148,
 29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
 55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217,
 206, 65, 226, 241, 55, 0, 110, 1, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
ExPlasma.decode(rlp, signed: false)
{:ok,
  %ExPlasma.Transaction{
    inputs: [
      %ExPlasma.Output{
        output_data: nil,
        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
        output_type: nil
      }
    ],
    metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    outputs: [
      %ExPlasma.Output{
        output_data: %{
          amount: 1,
          output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153,
            217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206,
            65, 226, 241, 55, 0, 110>>
        },
        output_id: nil,
        output_type: 1
      }
    ],
    witnesses: [],
    sigs: [],
    tx_data: 0,
    tx_type: 1
  }
}
```

You can validate a transaction by using `ExPlasma.validat/1`:

``` elixir
ExPlasma.Transaction.validate(txn)
```

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

## Contributing

1. [Fork it!](https://github.com/omgnetwork/ex_plasma)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

ExPlasma is released under the Apache-2.0 License.
