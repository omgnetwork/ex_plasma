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

  # Currently this is the only output type available.
  @payment_output_type 1

  # Contract settings
  @block_offset 1_000_000_000
  @transaction_offset 10_000

  defstruct blknum: @empty_integer,
            oindex: @empty_integer,
            txindex: @empty_integer,
            output_type: @payment_output_type,
            amount: @empty_integer,
            currency: @empty_address,
            owner: @empty_address

  @doc """
  Builds a Utxo

  ## Examples

      # Create a Utxo from an Output RLP list
      iex> alias ExPlasma.Transaction.Utxo
      iex> Utxo.new([<<1>>, <<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125, 202, 87, 133, 226, 40, 180>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, <<13, 224, 182, 179, 167, 100, 0, 0>>])
      %ExPlasma.Transaction.Utxo{
        amount: <<13, 224, 182, 179, 167, 100, 0, 0>>,
        blknum: 0,
        currency: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        oindex: 0,
        owner: <<205, 193, 229, 59, 220, 116, 187, 245, 181, 247, 21, 214, 50, 125,
          202, 87, 133, 226, 40, 180>>,
        txindex: 0
      }

      # Create a Utxo from an Input RLP Item
      iex> alias ExPlasma.Transaction.Utxo
      iex> Utxo.new(<<233, 16, 63, 218, 0>>)
      %ExPlasma.Transaction.Utxo{
        amount: 0,
        blknum: 1001,
        currency: "0x0000000000000000000000000000000000000000",
        oindex: 0,
        owner: "0x0000000000000000000000000000000000000000",
        txindex: 0
      }

      # Create a Utxo from a Utxo position.
      iex> alias ExPlasma.Transaction.Utxo
      iex> pos = 2000010001
      iex> Utxo.new(pos)
      %ExPlasma.Transaction.Utxo{
        amount: 0,
        blknum: 2,
        currency: "0x0000000000000000000000000000000000000000",
        oindex: 1,
        owner: "0x0000000000000000000000000000000000000000",
        txindex: 1
      }
  """
  def new([_output_type, owner, currency, amount]) do
    %__MODULE__{
      amount: amount,
      currency: currency,
      owner: owner
    }
  end

  def new(encoded_pos) when is_binary(encoded_pos),
    do: encoded_pos |> :binary.decode_unsigned(:big) |> new()

  def new(utxo_pos) when is_integer(utxo_pos) do
    blknum = div(utxo_pos, @block_offset)
    txindex = utxo_pos |> rem(@block_offset) |> div(@transaction_offset)
    oindex = rem(utxo_pos, @transaction_offset)
    %__MODULE__{blknum: blknum, txindex: txindex, oindex: oindex}
  end

  @doc """
  Returns the UTxo position(pos) number.

  ## Examples

    iex> alias ExPlasma.Transaction.Utxo
    iex> utxo = %Utxo{blknum: 2, oindex: 1, txindex: 1}
    iex> Utxo.pos(utxo)
    2000010001
  """
  def pos(%__MODULE__{blknum: blknum, oindex: oindex, txindex: txindex}),
    do: blknum * @block_offset + txindex * @transaction_offset + oindex

  @doc """
  Converts a Utxo into an RLP-encodable list. If your Utxo contains both sets of input/output data,
  use the `to_input_list` or `to_output_list` methods instead.

  ## Example

    # Convert from an `input` Utxo
    iex> alias ExPlasma.Transaction.Utxo
    iex> utxo = %Utxo{blknum: 2, oindex: 1, txindex: 1}
    iex> Utxo.to_list(utxo)
    <<119, 53, 187, 17>>

    # Convert from an `output` Utxo
    iex> alias ExPlasma.Transaction.Utxo
    iex> utxo = %Utxo{amount: 2}
    iex> Utxo.to_list(utxo)
    [<<1>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 2>>
    ]
  """
  def to_list(
        %__MODULE__{blknum: @empty_integer, oindex: @empty_integer, txindex: @empty_integer} =
          utxo
      ),
      do: to_output_list(utxo)

  def to_list(
        %__MODULE__{owner: @empty_address, currency: @empty_address, amount: @empty_integer} =
          utxo
      ),
      do: to_input_list(utxo)

  @doc """
  Convert a given utxo into an RLP-encodable input list.

  ## Examples

    iex> alias ExPlasma.Transaction.Utxo
    iex> %Utxo{} |> Utxo.to_input_list()
    <<0>>
  """
  @spec to_input_list(__MODULE__.t()) :: binary()
  def to_input_list(%__MODULE__{blknum: blknum, oindex: oindex, txindex: txindex} = utxo)
      when is_integer(blknum) and is_integer(oindex) and is_integer(txindex) do
    utxo |> pos() |> :binary.encode_unsigned(:big)
  end

  @doc """
  Convert a given Utxo into an RLP-encodable output list.

  ## Examples

    iex> alias ExPlasma.Transaction.Utxo
    iex> %Utxo{} |> Utxo.to_output_list()
    [
      <<1>>,
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0>>
    ]

    # Produces list with address hashes
    iex> alias ExPlasma.Transaction.Utxo
    iex> address = "0x0000000000000000000000000000000000000000"
    iex> %Utxo{owner: address, currency: address, amount: 1} |> Utxo.to_output_list()
    [
      <<1>>,
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      <<0, 0, 0, 0, 0, 0, 0, 1>>
    ]
  """
  @spec to_output_list(struct()) :: list(binary)
  def to_output_list(%__MODULE__{
        output_type: output_type,
        amount: amount,
        currency: <<_::336>> = currency,
        owner: <<_::336>> = owner
      }) do
    to_output_list(%__MODULE__{
      output_type: output_type,
      amount: amount,
      currency: to_binary(currency),
      owner: to_binary(owner)
    })
  end

  def to_output_list(%__MODULE__{
        output_type: output_type,
        amount: amount,
        currency: <<_::160>> = currency,
        owner: <<_::160>> = owner
      })
      when is_integer(amount) and amount >= 0 do
    [<<output_type>>, owner, currency, <<amount::integer-size(64)>>]
  end
end

defimpl ExPlasma.TypedData, for: ExPlasma.Transaction.Utxo do
  alias ExPlasma.Encoding
  alias ExPlasma.Transaction.Utxo

  @output_signature "Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)"
  @input_signature "Input(uint256 blknum,uint256 txindex,uint256 oindex)"

  @doc """
  """
  def encode(utxo), do: utxo |> Utxo.to_list() |> do_encode()

  def encode_input(utxo), do: utxo |> Utxo.to_input_list() |> do_encode()

  def encode_output(utxo), do: utxo |> Utxo.to_output_list() |> do_encode()

  def hash(%{} = utxo), do: utxo |> encode() |> hash()

  def hash([signature | encoded_list]),
    do:
      ([Encoding.keccak_hash(signature)] ++ encoded_list)
      |> Enum.join()
      |> Encoding.keccak_hash()

  defp do_encode([output_type, owner, currency, amount]) do
    [
      @output_signature,
      ABI.TypeEncoder.encode_raw([:binary.decode_unsigned(output_type)], [{:uint, 256}]),
      ABI.TypeEncoder.encode_raw([owner], [{:bytes, 20}]),
      ABI.TypeEncoder.encode_raw([currency], [:address]),
      ABI.TypeEncoder.encode_raw([amount], [{:uint, 256}])
    ]
  end

  defp do_encode(encoded_utxo_pos) do
    %Utxo{blknum: blknum, txindex: txindex, oindex: oindex} = encoded_utxo_pos |> Utxo.new()

    [
      @input_signature,
      ABI.TypeEncoder.encode_raw([blknum], [{:uint, 256}]),
      ABI.TypeEncoder.encode_raw([txindex], [{:uint, 256}]),
      ABI.TypeEncoder.encode_raw([oindex], [{:uint, 256}])
    ]
  end
end
