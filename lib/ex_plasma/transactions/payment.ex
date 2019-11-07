defmodule ExPlasma.Transactions.Payment do
  @moduledoc """
  A Payment Transaction type. Used to send transactions from one party to 
  another on the child chain.
  """

  @behaviour ExPlasma.Transaction

  @transaction_type 1

  # TODO
  # Do we need to think about moving this logic into the output itself?
  @output_type 1

  # A payment transaction is only allowed to have up to 4 inputs/outputs.
  @max_input_count 4
  @max_output_count 4

  @type t :: %__MODULE__{
          inputs: list(),
          outputs: list(map),
          metadata: binary()
        }

  defstruct(inputs: [], outputs: [], metadata: <<0::160>>)

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

  iex> input = %ExPlasma.Transaction.Input{}
  iex> output = %ExPlasma.Transaction.Output{}
  iex> ExPlasma.Transactions.Payment.new(inputs: [input], outputs: [output], metadata: nil)
  %ExPlasma.Transactions.Payment{
    inputs: [%ExPlasma.Transaction.Input{blknum: 0, oindex: 0, txindex: 0}],
    metadata: nil,
    outputs: [%ExPlasma.Transaction.Output{amount: 0, currency: 0, owner: 0}]
  }
  """
  @spec new(map()) :: __MODULE__.t()
  def new(inputs: inputs, outputs: outputs, metadata: metadata)
      when is_list(inputs) and length(inputs) <= @max_input_count
      when is_list(outputs) and length(outputs) <= @max_output_count do
    %__MODULE__{inputs: inputs, outputs: outputs, metadata: metadata}
  end
end
