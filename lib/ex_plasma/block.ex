defmodule ExPlasma.Block do
  @moduledoc """
    Encapsulates the block data we receive from the contract. It returns two things:

    * hash - The merkle root block hash of the plasma blocks.
    * transactions - the list of Transactions associated with this given block
  """

  alias ExPlasma.Merkle
  alias ExPlasma.Transaction

  @type t() :: %__MODULE__{
          hash: binary(),
          transactions: maybe_improper_list()
        }

  defstruct hash: nil, transactions: []

  # TODO
  #
  # Perhaps we need to do some validation check to prevent Deposit transactions from being included?
  @doc """
  Generate a new `Block` from a list of transactions

  ## Example

  iex> ExPlasma.Transaction.Type.PaymentV1.new([], []) |> List.wrap() |> ExPlasma.Block.new()
  %ExPlasma.Block{
    hash: <<184, 207, 88, 197, 184, 17, 244, 111, 210, 35, 71, 65, 116, 192, 87,
      64, 229, 29, 239, 171, 65, 160, 254, 111, 162, 170, 239, 180, 17, 151, 210,
      204>>,
    transactions: [
      %ExPlasma.Transaction.Type.PaymentV1{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        tx_data: 0,
        tx_type: 1
      }
    ]
  }
  """
  @spec new(maybe_improper_list()) :: t()
  def new(transactions) when is_list(transactions),
    do: %__MODULE__{transactions: transactions, hash: merkle_root_hash(transactions)}

  # Encode the transactions and merkle root hash them.
  defp merkle_root_hash(transactions) when is_list(transactions) do
    transactions
    |> Enum.map(&Transaction.encode/1)
    |> Merkle.root_hash()
  end
end
