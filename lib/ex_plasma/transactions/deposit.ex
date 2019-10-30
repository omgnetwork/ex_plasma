defmodule ExPlasma.Transactions.Deposit do
  @moduledoc """
  A Deposit `Transaction` type. We use this to
  send money into the contract to be used.
  """

  # The associated value for the transaction type. It's a hard coded
  # value you can find on the contracts:
  @transaction_type 1

  alias __MODULE__

  defstruct(
    inputs: [],
    outputs: [],
    metadata: nil
  )

  @type t :: %__MODULE__{
          inputs: list(),
          outputs: list(any),
          metadata: binary()
        }


  @doc """
  Encode the transaction with RLP

  ## Examples

      iex(1)> transaction = %ExPlasma.Transactions.Deposit{}
      iex(2)> ExPlasma.Transactions.Deposit.encode(transaction)
      <<227, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128, 128, 195,
        128, 128, 128, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128,
        128, 195, 128, 128, 128, 192>>
  """
  @spec encode(__MODULE__.t()) :: binary
  def encode(%__MODULE__{} = deposit), do: ExRLP.encode(deposit)

  @doc """
  Transforms the `Transaction` into a list, especially for encoding.

  ## Examples

      Transforms a Transaction into an RLP consumable list.
      iex(1)> transaction = %ExPlasma.Transactions.Deposit{}
      iex(2)> ExPlasma.Transactions.Deposit.to_list(transaction)
      [
        1,
        [],
        [],
        []
      ]
  """
  @spec to_list(t) :: list(any)
  def to_list(%Deposit{inputs: [], outputs: outputs, metadata: metadata}) do
    output_list = Enum.map(outputs, fn output -> Map.values(output) end)
    metadata_list = Enum.reject([metadata], &is_nil/1)
    [@transaction_type, [], output_list, metadata_list]
  end
end

defimpl ExRLP.Encode, for: ExPlasma.Transactions.Deposit do
  alias ExRLP.Encode
  alias ExPlasma.Transactions.Deposit, as: Transaction

  @doc """
  Encodes a `Transaction` into RLP

  ## Examples

      Encodes a transaction
      iex(1)> transaction = %ExPlasma.Transactions.Deposit{}
      iex(2)> ExRLP.encode(transaction)
      <<227, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128, 128, 195,
        128, 128, 128, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128,
        128, 195, 128, 128, 128, 192>>
  """
  @spec encode(Transaction.t(), keyword) :: binary
  def encode(transaction, options \\ []) do
    transaction
    |> Transaction.to_list()
    |> Encode.encode(options)
  end
end
