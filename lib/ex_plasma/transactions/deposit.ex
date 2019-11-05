defmodule ExPlasma.Transactions.Deposit do
  @moduledoc """
  A Deposit `Transaction` type. We use this to
  send money into the contract to be used.
  """

  @behaviour ExPlasma.Transaction

  @transaction_type 1
  @output_type 1

  alias __MODULE__
  alias ExPlasma.Transaction

  import ExPlasma.Encoding, only: [to_binary: 1]

  defstruct(
    inputs: [],
    outputs: [],
    metadata: <<0::160>>
  )

  @doc """
  The associated value for the output type. It's a hard coded
  value you can find on the contracts
  """
  @spec output_type() :: non_neg_integer()
  def output_type(), do: @output_type

  @doc """
  The associated value for the transaction type. It's a hard coded
  value you can find on the contracts
  """
  @spec transaction_type() :: non_neg_integer()
  def transaction_type(), do: @transaction_type

  @doc """
  Generate a new Deposit transaction struct which should:
    * have 0 inputs
    * have 1 output, containing the owner, currency, and amount

  ## Examples

  iex> ExPlasma.Transactions.Deposit.new("dog", "eth", 1, "dog money")
  %ExPlasma.Transactions.Deposit{
    inputs: [],
    metadata: "dog money",
    outputs: [%{amount: 1, currency: "eth", owner: "dog"}]
  }
  """
  def new(owner, currency, amount, metadata) do
    output = %{owner: owner, currency: currency, amount: amount}
    new(inputs: [], outputs: [output], metadata: metadata)
  end

  def new(inputs: inputs, outputs: outputs, metadata: metadata),
    do: %__MODULE__{inputs: inputs, outputs: outputs, metadata: metadata}
end
