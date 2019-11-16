defmodule ExPlasma.Transactions.Payment do
  @moduledoc """
  A Payment Transaction type. Used to send transactions from one party to 
  another on the child chain.
  """

  alias ExPlasma.Transaction

  @behaviour Transaction

  @transaction_type 1
  @output_type 1

  # A payment transaction is only allowed to have up to 4 inputs/outputs.
  @max_input_count 4
  @max_output_count 4

  @type t :: %__MODULE__{
          inputs: list(),
          outputs: list(map),
          metadata: binary()
        }

  defstruct(sigs: [], inputs: [], outputs: [], metadata: nil)

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
  Creates a new `Transaction` struct, filling the inputs and outputs
  to the default sizes (see @contract_input_count and @contract_output_count).

  ## Examples

  iex> alias ExPlasma.Transaction.Utxo
  iex> alias ExPlasma.Transactions.Payment
  iex> address = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
  iex> currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
  iex> utxo = %Utxo{owner: address, currency: currency, amount: 1}
  iex> Payment.new(%{inputs: [], outputs: [utxo]})
  %ExPlasma.Transactions.Payment{
    inputs: [],
    sigs: [],
    metadata: nil,
    outputs: [%ExPlasma.Transaction.Utxo{
      amount: 1,
      blknum: 0,
      currency: "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e",
      oindex: 0,
      owner: "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e",
      txindex: 0}]
  }
  """
  @spec new(map()) :: __MODULE__.t()
  def new(%{inputs: inputs, outputs: outputs} = payment)
      when is_list(inputs) and length(inputs) <= @max_input_count and
             is_list(outputs) and length(outputs) <= @max_output_count do
    Transaction.new(struct(__MODULE__, payment))
  end
end
