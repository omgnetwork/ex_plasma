defmodule ExPlasma.Utxo do
  @moduledoc """
  A `Utxo` is an unspent transaction output. They come in two distinct forms:

  * An `output`: An output utxo is created whenever a transaction has value that is
                 designated to someone(marked as the new `owner`). In order to 
                 form a output utxo, you'll need 4 fields specifically:

      - output_type: This is the integer value of the output_type. This is set on the contract
                     but also currently hard-coded to `1`, as there is only one output type
                     currently.
      - owner:       this is the new owner of the output. You can think of this as who
                     the value(or `amount`) is be re-attributed to.
      - currency:    This is an address/address hash that resolves to the currency/token's
                     address on the network. Ether is designated at <<0::160>>.
      - amount:      This is the amount that is contained in the utxo and who it's being
                     given to.(see `owner`).

  * An `input`: An input utxo is used/spent whenever you are making a transaction to
                another party. Most transactions(except Deposit) expects you to have
                an `input` in order to create an `output` on a transaction. Since these
                were previously `outputs` but have been stored, you'll need these fields 
                to specify an `input`:

      - blknum:  The block number at which this `input` utxo was created.
                 (See the transaction which this `input` was first created as an `output`).
      - txindex: The transaction index for the given utxo.
      - oindex:  The offset index for the given utxo. TODO
  """

  alias ExPlasma.Transaction
  import ExPlasma.Encoding, only: [to_binary: 1, to_int: 1]

  @type t :: %__MODULE__{
          blknum: non_neg_integer() | nil,
          oindex: non_neg_integer() | nil,
          txindex: non_neg_integer() | nil,
          amount: non_neg_integer() | nil,
          currency: Transaction.address() | Transaction.address_hash() | nil,
          owner: Transaction.address() | Transaction.address_hash() | nil
        }

  # Currently this is the only output type available.
  @payment_output_type 1

  # Contract settings
  # These are being hard-coded from the same values on the contracts.
  # See: https://github.com/omisego/plasma-contracts/blob/master/plasma_framework/contracts/src/utils/PosLib.sol#L16-L23
  @block_offset 1_000_000_000
  @transaction_offset 10_000
  @max_txindex :math.pow(2, 16) - 1
  @max_blknum (:math.pow(2, 54) - 1 - @max_txindex) / (@block_offset / @transaction_offset)

  defstruct blknum: nil,
            oindex: nil,
            txindex: nil,
            output_type: @payment_output_type,
            amount: nil,
            currency: nil,
            owner: nil

  @doc """
  Builds a new Utxo.

  ## Examples

      # Create a Utxo from an Output RLP list
      iex> alias ExPlasma.Utxo
      iex> Utxo.new([<<1>>, [<<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125, 202, 87, 133, 226, 40, 180>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, <<13, 224, 182, 179, 167, 100, 0, 0>>]])
      {:ok, %ExPlasma.Utxo{
        amount: 1000000000000000000,
        blknum: nil,
        currency: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        oindex: nil,
        output_type: 1,
        owner: <<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125,
          202, 87, 133, 226, 40, 180>>,
        txindex: nil
      }}

      # Create a Utxo from an Input RLP Item (encoded utxo position)
      iex> alias ExPlasma.Utxo
      iex> Utxo.new(<<233, 16, 63, 218, 0>>)
      {:ok, %ExPlasma.Utxo{
        amount: nil,
        blknum: 1001,
        currency: nil,
        oindex: 0,
        owner: nil,
        txindex: 0
      }}

      # Create a Utxo from a Utxo position.
      iex> alias ExPlasma.Utxo
      iex> pos = 2000010001
      iex> Utxo.new(pos)
      {:ok, %ExPlasma.Utxo{
        amount: nil,
        blknum: 2,
        currency: nil,
        oindex: 1,
        owner: nil,
        txindex: 1
      }}
  """
  @spec new(binary() | nonempty_maybe_improper_list() | non_neg_integer()) ::
          {:ok, __MODULE__.t()} | {:error, {atom(), atom()}}
  def new(data) when is_list(data), do: data |> do_new() |> validate_output()
  def new(%__MODULE__{owner: nil, currency: nil, amount: nil} = data), do: validate_input(data)
  def new(%__MODULE__{} = data), do: validate_output(data)
  def new(data), do: {:ok, do_new(data)}

  @doc """
  Returns the Utxo position(pos) number.

  ## Examples

    iex> alias ExPlasma.Utxo
    iex> utxo = %Utxo{blknum: 2, oindex: 1, txindex: 1}
    iex> Utxo.pos(utxo)
    2000010001
  """
  def pos(%{blknum: blknum, oindex: oindex, txindex: txindex}),
    do: blknum * @block_offset + txindex * @transaction_offset + oindex

  @doc """
  Converts a Utxo into an RLP-encodable list. If your Utxo contains both sets of input/output data,
  use the `to_input_rlp` or `to_output_rlp` methods instead.

  ## Example

    # Convert from an `input` Utxo
    iex> alias ExPlasma.Utxo
    iex> utxo = %Utxo{blknum: 2, oindex: 1, txindex: 1}
    iex> Utxo.to_rlp(utxo)
    <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 119, 53, 187, 17>>

    # Convert from an `output` Utxo
    iex> alias ExPlasma.Utxo
    iex> utxo = %Utxo{amount: 2, currency: <<0::160>>, owner: <<0::160>>}
    iex> Utxo.to_rlp(utxo)
    [<<1>>, [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<2>>]
    ]
  """
  def to_rlp(%{owner: nil, currency: nil, amount: nil} = utxo),
    do: to_input_rlp(utxo)

  def to_rlp(%{blknum: nil, oindex: nil, txindex: nil} = utxo),
    do: to_output_rlp(utxo)

  @doc """
  Convert a given utxo into an RLP-encodable input list.

  ## Examples

    iex> alias ExPlasma.Utxo
    iex> utxo = %Utxo{blknum: 2, oindex: 1, txindex: 1}
    iex> Utxo.to_input_rlp(utxo)
    <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 119, 53, 187, 17>>
  """
  @spec to_input_rlp(__MODULE__.t()) :: binary()
  def to_input_rlp(%{blknum: blknum, oindex: oindex, txindex: txindex} = utxo)
      when is_integer(blknum) and is_integer(oindex) and is_integer(txindex) do
    utxo |> pos() |> :binary.encode_unsigned(:big) |> pad_binary()
  end

  @doc """
  Convert a given Utxo into an RLP-encodable output list.

  ## Examples

    iex> alias ExPlasma.Utxo
    iex> Utxo.to_output_rlp(%Utxo{amount: 0, currency: <<0::160>>, owner: <<0::160>>})
    [
      <<1>>,
      [
        <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        <<0>>
      ]
    ]

    # Produces list with address hashes
    iex> alias ExPlasma.Utxo
    iex> address = "0x0000000000000000000000000000000000000000"
    iex> Utxo.to_output_rlp(%Utxo{owner: address, currency: address, amount: 1})
    [
      <<1>>,
      [
        <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        <<1>>
      ]
    ]
  """
  @spec to_output_rlp(struct()) :: list()
  def to_output_rlp(%{amount: amount} = utxo) when is_integer(amount),
    do: to_output_rlp(%{utxo | amount: <<amount::integer-size(256)>>})

  def to_output_rlp(%{currency: <<_::336>> = currency} = utxo),
    do: to_output_rlp(%{utxo | currency: to_binary(currency)})

  def to_output_rlp(%{owner: <<_::336>> = owner} = utxo),
    do: to_output_rlp(%{utxo | owner: to_binary(owner)})

  def to_output_rlp(%{currency: <<_::160>>, owner: <<_::160>>, amount: <<_::256>>} = utxo),
    do: [<<utxo.output_type>>, [utxo.owner, utxo.currency, truncate_leading_zero(utxo.amount)]]

  defp do_new([<<output_type>>, rest_of_output]), do: do_new([output_type, rest_of_output])

  defp do_new([output_type, [owner, currency, amount]]) when is_integer(amount),
    do: %__MODULE__{output_type: output_type, amount: amount, currency: currency, owner: owner}

  defp do_new([output_type, [owner, currency, amount]]),
    do: do_new([output_type, [owner, currency, to_int(amount)]])

  defp do_new(encoded_pos) when is_binary(encoded_pos) and byte_size(encoded_pos) <= 32,
    do: encoded_pos |> :binary.decode_unsigned(:big) |> do_new()

  defp do_new(utxo_pos) when is_integer(utxo_pos) do
    blknum = div(utxo_pos, @block_offset)
    txindex = utxo_pos |> rem(@block_offset) |> div(@transaction_offset)
    oindex = rem(utxo_pos, @transaction_offset)
    %__MODULE__{blknum: blknum, txindex: txindex, oindex: oindex}
  end

  defp pad_binary(unpadded) do
    pad_size = (32 - byte_size(unpadded)) * 8
    <<0::size(pad_size)>> <> unpadded
  end

  defp truncate_leading_zero(<<0>>), do: <<0>>
  defp truncate_leading_zero(<<0>> <> binary), do: truncate_leading_zero(binary)
  defp truncate_leading_zero(binary), do: binary

  # Validates that the Utxo is in the expected formats. Returns an error tuple
  defp validate_output(%{owner: <<0::160>>}), do: {:error, {:owner, :cannot_be_zero}}
  defp validate_output(%{amount: 0}), do: {:error, {:amount, :cannot_be_zero}}

  defp validate_output(%{amount: nil, currency: _, owner: _}),
    do: {:error, {:amount, :cannot_be_nil}}

  defp validate_output(%{amount: _, currency: nil, owner: _}),
    do: {:error, {:currency, :cannot_be_nil}}

  defp validate_output(%{amount: _, currency: _, owner: nil}),
    do: {:error, {:owner, :cannot_be_nil}}

  defp validate_output(%{} = utxo), do: {:ok, utxo}

  defp validate_input(%{blknum: nil, txindex: _, oindex: _}),
    do: {:error, {:blknum, :cannot_be_nil}}

  defp validate_input(%{blknum: _, txindex: nil, oindex: _}),
    do: {:error, {:txindex, :cannot_be_nil}}

  defp validate_input(%{blknum: _, txindex: _, oindex: nil}),
    do: {:error, {:oindex, :cannot_be_nil}}

  defp validate_input(%{blknum: blknum}) when is_integer(blknum) and blknum > @max_blknum,
    do: {:error, {:blknum, :exceeds_maximum}}

  defp validate_input(%{txindex: txindex}) when is_integer(txindex) and txindex > @max_txindex,
    do: {:error, {:txindex, :exceeds_maximum}}

  defp validate_input(%{} = utxo), do: {:ok, utxo}
end
