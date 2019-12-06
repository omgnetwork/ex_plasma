defmodule ExPlasma.Block do
  @moduledoc """
    Encapsulates the block data we receive from the contract. It returns two things:

    * hash - The merkle root block hash of the plasma blocks.
    * transactions - the list of Transactions associated with this given block
  """

  @type t() :: %__MODULE__{
          hash: binary() | nil,
          timestamp: non_neg_integer() | nil,
          transactions: maybe_improper_list()
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
      hash: <<7, 125, 211, 138, 245, 129, 180, 55, 107, 36, 130, 187, 75, 69, 154,
      115, 240, 9, 134, 6, 51, 31, 54, 52, 138, 115, 33, 50, 166, 121, 170, 131>>,
      timestamp: nil,
      transactions: [
        %ExPlasma.Transaction{inputs: [], metadata: nil, outputs: [], sigs: []}
      ]
    }
  """
  @spec new(maybe_improper_list()) :: __MODULE__.t()
  def new(transactions) when is_list(transactions),
    do: %__MODULE__{transactions: transactions, hash: merkle_root_hash(transactions)}

  # Encode the transactions and merkle root hash them.
  defp merkle_root_hash(transactions) when is_list(transactions),
    do: Encoding.merkle_root_hash(Enum.map(transactions, &Transaction.encode/1))
end
