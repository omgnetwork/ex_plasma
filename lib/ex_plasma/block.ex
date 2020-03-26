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
      hash: <<162, 30, 56, 202, 121, 64, 48, 158, 182, 172, 255, 172, 103, 46, 193, 151, 236, 162, 92, 242, 78, 195, 132, 176, 200, 239, 249, 20, 160, 176, 63, 29>>,
      timestamp: nil,
      transactions: [
        %ExPlasma.Transaction{inputs: [], metadata: nil, outputs: [], sigs: []}
      ]
    }
  """
  @spec new(maybe_improper_list()) :: %__MODULE__{hash: binary(), timestamp: nil, transactions: maybe_improper_list}
  def new(transactions) when is_list(transactions),
    do: %__MODULE__{transactions: transactions, hash: merkle_root_hash(transactions)}

  # Encode the transactions and merkle root hash them.
  defp merkle_root_hash(transactions) when is_list(transactions) do
    transactions
    |> Enum.map(&Transaction.encode/1)
    |> Encoding.merkle_root_hash()
  end
end
