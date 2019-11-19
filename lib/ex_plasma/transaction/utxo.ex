defmodule ExPlasma.Transaction.Utxo do
  @moduledoc """
  Represents an unspent output. This struct exits in two forms:

  * An `output` where the `owner`, `currency`, and `amount` 
    are specified in a transaction.
  * An `input` where the `blknum`, `txindex`, and `oindex`
    are specified in a transaction.
  """

  alias ExPlasma.Transaction
  import ExPlasma.Encoding, only: [to_binary: 1, to_hex: 1]

  @type t :: %__MODULE__{
          blknum: non_neg_integer(),
          oindex: non_neg_integer(),
          txindex: non_neg_integer(),
          amount: non_neg_integer(),
          currency: Transaction.address() | Transaction.address_hash(),
          owner: Transaction.address() | Transaction.address_hash()
        }

  @empty_integer 0
  @empty_address to_hex(<<0::160>>)

  defstruct blknum: @empty_integer,
            oindex: @empty_integer,
            txindex: @empty_integer,
            amount: @empty_integer,
            currency: @empty_address,
            owner: @empty_address

  @doc """
  Convert a given utxo into an RLP-encodable input list.

  ## Examples

    iex> alias ExPlasma.Transaction.Utxo
    iex> %Utxo{} |> Utxo.to_input_list()
    [
      <<0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0>>
    ]
  """
  @spec to_input_list(__MODULE__.t()) :: list(binary)
  def to_input_list(%__MODULE__{blknum: blknum, oindex: oindex, txindex: txindex})
      when is_integer(blknum) and is_integer(oindex) and is_integer(txindex) do
    [<<blknum::integer-size(64)>>, <<txindex::integer-size(64)>>, <<oindex::integer-size(64)>>]
  end

  @doc """
  Convert a given Utxo into an RLP-encodable output list.

  ## Examples

    iex> alias ExPlasma.Transaction.Utxo
    iex> %Utxo{} |> Utxo.to_output_list()
    [
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0>>
    ]

    # Produces list with address hashes
    iex> alias ExPlasma.Transaction.Utxo
    iex> address = "0x0000000000000000000000000000000000000000"
    iex> %Utxo{owner: address, currency: address, amount: 1} |> Utxo.to_output_list()
    [
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 1>>
    ]
  """
  @spec to_output_list(struct()) :: list(binary)
  def to_output_list(%__MODULE__{
        amount: amount,
        currency: <<_::336>> = currency,
        owner: <<_::336>> = owner
      }) do
    to_output_list(%__MODULE__{
      amount: amount,
      currency: to_binary(currency),
      owner: to_binary(owner)
    })
  end

  def to_output_list(%__MODULE__{
        amount: amount,
        currency: <<_::160>> = currency,
        owner: <<_::160>> = owner
      })
      when is_integer(amount) and amount >= 0 do
    [owner, currency, <<amount::integer-size(64)>>]
  end
end
