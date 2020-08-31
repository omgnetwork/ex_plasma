defmodule ExPlasma.Output.Position do
  @moduledoc """
  Generates an Output position if given the:

  `blknum` - The block number for this output
  `txindex` - The index of the Transaction in the block.
  `oindex` - The index of the Output in the Transaction.
  """

  @behaviour ExPlasma.Output

  alias __MODULE__.Validator
  alias ExPlasma.Output
  alias ExPlasma.Utils.RlpDecoder

  @type position() :: pos_integer()

  @type t() :: %{
          position: position(),
          blknum: non_neg_integer(),
          txindex: non_neg_integer(),
          oindex: non_neg_integer()
        }

  @type validation_responses() ::
          :ok
          | {:error,
             Validator.blknum_validation_errors()
             | Validator.oindex_validation_errors()
             | Validator.txindex_validation_errors()}

  # Contract settings
  # These are being hard-coded from the same values on the contracts.
  # See: https://github.com/omisego/plasma-contracts/blob/master/plasma_framework/contracts/src/utils/PosLib.sol#L16-L23
  @block_offset 1_000_000_000
  @transaction_offset 10_000

  def block_offset(), do: @block_offset
  def transaction_offset(), do: @transaction_offset

  @doc """
  Encodes the blknum, txindex, and oindex into a single integer.

  ## Example

  iex> pos = %{blknum: 1, txindex: 0, oindex: 0}
  iex> ExPlasma.Output.Position.pos(pos)
  1_000_000_000
  """
  @spec pos(t()) :: position()
  def pos(%{blknum: blknum, txindex: txindex, oindex: oindex}) do
    blknum * @block_offset + txindex * @transaction_offset + oindex
  end

  @doc """
  Transforms the output position into a positive integer representing the position.

  ## Example

  iex> output_id = %{blknum: 1, txindex: 0, oindex: 0}
  iex> ExPlasma.Output.Position.to_rlp(output_id)
  <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0>>
  """
  @impl Output
  @spec to_rlp(t()) :: binary()
  def to_rlp(output_id), do: output_id |> pos() |> encode()

  @doc """
  Encodes the output position into an RLP encodable object.

  ## Example

  iex> pos = ExPlasma.Output.Position.pos(%{blknum: 1, txindex: 0, oindex: 0})
  iex> ExPlasma.Output.Position.encode(pos)
  <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0>>
  """
  @spec encode(position()) :: binary()
  def encode(position) do
    position |> :binary.encode_unsigned(:big) |> pad_binary()
  end

  @doc """
  Returns a map of the decoded position.

  ## Example

  iex> pos = 1_000_000_000
  iex> ExPlasma.Output.Position.to_map(pos)
  {:ok, %{position: 1_000_000_000, blknum: 1, txindex: 0, oindex: 0}}
  """
  @impl Output
  @spec to_map(position()) :: {:ok, t()} | {:error, :malformed_output_position}
  def to_map(pos) when is_integer(pos) do
    blknum = div(pos, @block_offset)
    txindex = pos |> rem(@block_offset) |> div(@transaction_offset)
    oindex = rem(pos, @transaction_offset)

    {:ok, %{position: pos, blknum: blknum, txindex: txindex, oindex: oindex}}
  end

  def to_map(_), do: {:error, :malformed_output_position}

  @doc """
  Decodes and returns the integer position.

  ## Example

  iex> pos = <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0>>
  iex> ExPlasma.Output.Position.decode(pos)
  {:ok, 1_000_000_000}
  """
  @spec decode(binary()) :: {:ok, position()} | {:error, :malformed_input_position_rlp}
  def decode(encoded_pos) do
    case RlpDecoder.parse_uint256_with_leading(encoded_pos) do
      {:ok, pos} -> {:ok, pos}
      _error -> {:error, :malformed_input_position_rlp}
    end
  end

  @doc """
  Validates that values can give a valid position.

  ## Example
  iex> output_id = %{blknum: 1, txindex: 0, oindex: 0}
  iex> ExPlasma.Output.Position.validate(output_id)
  :ok
  """
  @impl Output
  @spec validate(t()) :: validation_responses()
  def validate(nil), do: :ok

  def validate(output_id) do
    with :ok <- Validator.validate_blknum(output_id.blknum),
         :ok <- Validator.validate_txindex(output_id.txindex),
         :ok <- Validator.validate_oindex(output_id.oindex) do
      :ok
    end
  end

  defp pad_binary(unpadded) do
    pad_size = (32 - byte_size(unpadded)) * 8
    <<0::size(pad_size)>> <> unpadded
  end
end
