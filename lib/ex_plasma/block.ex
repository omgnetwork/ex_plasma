defmodule ExPlasma.Block do
  @moduledoc """
    Encapsulates the block data we receive from the contract. It returns two things:

    * hash - The merkle root block hash of the plasma blocks.
    * transactions - the list of Transactions associated with this given block
  """

  # TODO achiurizo
  # narrow the type definition
  @type t() :: %__MODULE__{
          hash: binary(),
          timestamp: non_neg_integer(),
          transactions: list(Transaction.t())
        }

  defstruct(hash: nil, timestamp: nil, transactions: [])

  alias ExPlasma.Encoding
  alias ExPlasma.Transaction

  # TODO
  #
  # Perhaps we need to do some validation check to prevent Deposit transactions from being included?
  @doc """
  Generate a new `Block` from a list of transactions

  ## Example

    iex> %ExPlasma.Transaction{} |> List.wrap() |> ExPlasma.Block.new
    %ExPlasma.Block{
      hash: <<223, 96, 101, 248, 81, 250, 16, 13, 34, 24, 61, 77, 203, 50, 91, 79,
        208, 239, 84, 191, 208, 233, 166, 0, 105, 150, 209, 251, 94, 178, 255, 30>>,
      timestamp: nil,
      transactions: [
        %ExPlasma.Transaction{inputs: [], metadata: nil, outputs: [], sigs: []}
      ]
    }
  """
  @spec new(list(Transaction.t())) :: __MODULE__.t()
  def new(transactions) when is_list(transactions),
    do: %__MODULE__{transactions: transactions, hash: merkle_root_hash(transactions)}

  # Encode the transactions and merkle root hash them.
  defp merkle_root_hash(transactions) when is_list(transactions),
    do: Encoding.merkle_root_hash(Enum.map(transactions, &Transaction.encode/1))
end
