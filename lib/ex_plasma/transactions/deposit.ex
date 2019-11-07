defmodule ExPlasma.Transactions.Deposit do
  @moduledoc """
  A Deposit `Transaction` type. We use this to send money into the contract 
  to be used. This is really just a Payment Transaction with no inputs
  """

  @behaviour ExPlasma.Transaction

  # A Deposit Transaction is really a Payment Transaction according
  # to the contracts. Therefor, the markers here are the same.
  @transaction_type 1

  # TODO
  # Do we need to think about moving this logic into the output itself?
  @output_type 1

  # A Deposit transaction can only have 0 inputs and 1 output.
  @max_input_count 0
  @max_output_count 1

  @type t :: %__MODULE__{
          inputs: list(),
          outputs: list(map),
          metadata: binary()
        }

  defstruct(sigs: [], inputs: [], outputs: [], metadata: <<0::160>>)

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

  def new(inputs: inputs, outputs: outputs, metadata: metadata)
      when is_list(inputs) and length(inputs) == @max_input_count and
             is_list(outputs) and length(outputs) == @max_output_count do
    %__MODULE__{inputs: inputs, outputs: outputs, metadata: metadata}
  end
end
