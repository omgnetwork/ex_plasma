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

  iex> %ExPlasma.Transaction{tx_type: 1} |> List.wrap() |> ExPlasma.Block.new()
  %ExPlasma.Block{
    hash: <<168, 54, 172, 201, 1, 212, 18, 167, 34, 57, 232, 89, 151, 225, 172,
      150, 208, 77, 194, 12, 174, 250, 146, 254, 93, 42, 28, 253, 203, 237, 247,
      62>>,
    transactions: [
      %ExPlasma.Transaction{
        sigs: [],
        witnesses: [],
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
  def new(transactions) do
    %__MODULE__{transactions: transactions, hash: merkle_root_hash(transactions)}
  end

  # Encode the transactions and merkle root hash them.
  defp merkle_root_hash(transactions) do
    transactions
    |> Enum.map(fn tx -> Transaction.encode(tx, signed: false) end)
    |> Merkle.root_hash()
  end
end
