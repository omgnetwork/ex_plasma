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
  authority_address: "0x22d491bde2303f2f43325b2108d26f1eaba1e32b",
  contract_address: "0xd17e1233a03affb9092d5109179b43d6a8828607",
  eth_vault_address: "0x1967d06b1faba91eaadb1be33b277447ea24fa0e",
  exit_game_address: "0x902719f192aa5240632f704aa7a94bab61b86550",
  gas: 1_000_000,
  gas_price: 1_000_000,
  standard_exit_bond_size: 14_000_000_000_000_000,
  eip_712_domain: [
    name: "ExPlasma",
    salt: "some-salt",
    verifying_contract: "contract_address",
    version: "1"
  ]
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

## Usage

### Depositing to the Contract

#### Creating an eth deposit transaction

```elixir
alias ExPlasma.Transactions.Deposit
alias ExPlasma.Utxo

%Utxo{owner: <<0::160>>, currency: <<0::160>>, amount: 100}
|> Deposit.new()

# or with keywords
Deposit.new(owner: <<0::160>>, currency: <<0::160>>, amount: 100)
#=>

%ExPlasma.Transactions.Deposit{
  inputs: [],
  metadata: nil,
  outputs: [
    %ExPlasma.Utxo{
      amount: 100,
      blknum: 0,
      currency: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      oindex: 0,
      output_type: 1,
      owner: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      txindex: 0
    }
  ],
  sigs: []
}
```

#### Sending the deposit transaction to the contract

```elixir
alias ExPlasma.Client
alias ExPlasma.Transactions.Deposit

{:ok, receipt_hash} = 
  Deposit.new(owner: <<0::160>>, currency: <<0::160>>, amount: 100)
  |> Client.deposit()
```


#### Decoding a Transaction

```elixir
tx_bytes = 
  <<248, 77, 1, 192, 245, 244, 1, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 136, 0, 0, 0, 0, 0, 0, 0, 100, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0>>

ExPlasma.Transaction.decode(tx_bytes)

#=>
%ExPlasma.Transaction{
  inputs: [],
  metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
  outputs: [
    %ExPlasma.Utxo{
      amount: <<0, 0, 0, 0, 0, 0, 0, 100>>,
      blknum: 0,
      currency: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      oindex: 0,
      output_type: 1,
      owner: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      txindex: 0
    }
  ],
  sigs: []
}
```

### Generating and Submitting Blocks
#### Creating a block

```elixir
utxo = %Utxo{blknum: 1}
output = %Utxo{owner: <<0::160>>, amount: 1}
Payment.new(%{inputs: [utxo], outputs: [output]})
|> List.wrap()
|> Block.new()
#=> 
%ExPlasma.Block{
  hash: <<1, 16, 81, 170, 227, 107, 163, 227, 126, 169, 45, 179, 200, 94, 182,
    192, 241, 138, 24, 219, 149, 122, 252, 243, 115, 35, 14, 69, 152, 11, 98,
    200>>,
  timestamp: nil,
  transactions: [
    %ExPlasma.Transactions.Payment{
      inputs: [
        %ExPlasma.Utxo{
          amount: 0,
          blknum: 1,
          currency: "0x0000000000000000000000000000000000000000",
          oindex: 0,
          output_type: 1,
          owner: "0x0000000000000000000000000000000000000000",
          txindex: 0
        }
      ],
      metadata: nil,
      outputs: [
        %ExPlasma.Utxo{
          amount: 1,
          blknum: 0,
          currency: "0x0000000000000000000000000000000000000000",
          oindex: 0,
          output_type: 1,
          owner: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
          txindex: 0
        }
      ],
      sigs: []
    }
  ]
}
```

#### Submitting a block to the contract

```elixir
utxo = %Utxo{blknum: 1}
output = %Utxo{owner: <<0::160>>, amount: 1}
{:ok, _receipt_hash} =
Payment.new(%{inputs: [utxo], outputs: [output]})
|> List.wrap() 
|> Block.new()
|> Client.submit_block()
```

### Standard Exits
#### Starting a standard exit

These are more complicated flows that require you to have a valid transaction
already existing on the network. You can see the [integration tests](test/integration/standard_exit_test.exs) for an example how to achieve the full
flow. If you were to however have the data on hand, you can pass it to the contract as such:

```elixir
Client.start_standard_exit(tx_bytes, %{
 from: authority_address(),
 utxo_pos: utxo_pos,
 proof: proof
})
```
#### Processing a standard exit
#### Challenge a standard exit

### InFlight Exits
#### Starting an in-flight exit
#### Processing an in-flight exit
#### Challenge an in-flight exit

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_plasma](https://hexdocs.pm/ex_plasma).
