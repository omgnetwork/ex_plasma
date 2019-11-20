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

## WIP

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

### Usage



### Depositing to the Contract
#### Creating an eth deposit transaction
#### Sending the deposit transaction to the contract
#### Decoding a deposit transaction

### Generating and Submitting Blocks
#### Creating a block
#### Submitting a block to the contract

### Standard Exits
#### Starting a standard exit
#### Processing a standard exit
#### Challenge a standard exit

### InFlight Exits
#### Starting an in-flight exit
#### Processing an in-flight exit
#### Challenge an in-flight exit



##### Creating a Transaction

To work with the contracts, we need to understand the different flows and transaction available.

###### Creating a Deposit transaction

##### Depositing Eth into the contract

```elixir
alias ExPlasma.Client
alias ExPlasma.Transaction.Utxo
alias ExPlasma.Transactions.Deposit

owner_address = "0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b"
currency_address = "0x0000000000000000000000000000000000000000"

%Utxo{owner: owner_address, currency_address: currency_address, amount: 1}
|> Deposit.new()
|> Client.deposit()
```

##### Submitting a Block as an Authority

```elixir
alias ExPlasma.Transaction.Output
alias ExPlasma.Transaction.Input0

authority = "0x22d491bde2303f2f43325b2108d26f1eaba1e32b"
currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
metadata = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
output = %Output{owner: authority, currency: currency, amount: 1}
input = %Input{}
transaction = Payment.new(inputs: [input], outputs: [output], metadata: metadata)

 Block.new([transaction])
 |> Client.submit_block()
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_plasma](https://hexdocs.pm/ex_plasma).
