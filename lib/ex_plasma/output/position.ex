defmodule ExPlasma.Output.Position do
  @moduledoc """
  Generates an Output position if given the:

  `blknum` - The block number for this output
  `txindex` - The index of the Transaction in the block.
  `oindex` - The index of the Output in the Transaction.
  """

  @behaviour ExPlasma.Output

  alias ExPlasma.Output

  @type position() :: pos_integer()

  @type t() :: %{
          position: position(),
          blknum: non_neg_integer(),
          txindex: non_neg_integer(),
          oindex: non_neg_integer()
        }

  @type validation_responses() ::
          {:ok, t() | Output.t()}
          | {:error, {:blknum, :cannot_be_nil}}
          | {:error, {:blknum, :cannot_exceed_maximum_value}}
          | {:error, {:oindex, :cannot_be_nil}}
          | {:error, {:txindex, :cannot_be_nil}}
          | {:error, {:txindex, :cannot_exceed_maximum_value}}

  # Contract settings
  # These are being hard-coded from the same values on the contracts.
  # See: https://github.com/omisego/plasma-contracts/blob/master/plasma_framework/contracts/src/utils/PosLib.sol#L16-L23
  @block_offset 1_000_000_000
  @transaction_offset 10_000
  @max_txindex :math.pow(2, 16) - 1
  @max_blknum (:math.pow(2, 54) - 1 - @max_txindex) / (@block_offset / @transaction_offset)

  @doc """
  Encodes the blknum, txindex, and oindex into a single integer.

  ## Example

  iex> pos = %{blknum: 1, txindex: 0, oindex: 0}
  iex> ExPlasma.Output.Position.pos(pos)
  1_000_000_000
  """
  @spec pos(t()) :: number()
  def pos(%{blknum: blknum, txindex: txindex, oindex: oindex}) do
    blknum * @block_offset + txindex * @transaction_offset + oindex
  end

  @doc """
  Encodes the output position into an RLP encodeable object.

  ## Example

  iex> pos = %{blknum: 1, txindex: 0, oindex: 0}
  iex> ExPlasma.Output.Position.to_rlp(pos)
  <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0>>
  """
  @impl Output
  @spec to_rlp(t()) :: binary()
  def to_rlp(%{blknum: _, txindex: _, oindex: _} = id) do
    id |> pos() |> :binary.encode_unsigned(:big) |> pad_binary()
  end

  @doc """
  Returns a map of the decoded position.

  ## Example

  iex> pos = 1_000_000_000
  iex> ExPlasma.Output.Position.to_map(pos)
  %{position: 1_000_000_000, blknum: 1, txindex: 0, oindex: 0}
  """
  @impl Output
  @spec to_map(position()) :: t()
  def to_map(pos) do
    blknum = div(pos, @block_offset)
    txindex = pos |> rem(@block_offset) |> div(@transaction_offset)
    oindex = rem(pos, @transaction_offset)

    %{position: pos, blknum: blknum, txindex: txindex, oindex: oindex}
  end

  @doc """
  Validates that values can give a valid position.

  ## Example
  iex> pos = %{blknum: 1, txindex: 0, oindex: 0}
  iex> {:ok, resp} = ExPlasma.Output.Position.validate(pos)
  {:ok, %{blknum: 1, txindex: 0, oindex: 0}}
  """
  @impl Output
  @spec validate(t()) :: validation_responses()
  def validate(%{blknum: blknum, txindex: txindex, oindex: oindex} = pos) do
    case do_validate({blknum, txindex, oindex}) do
      {field, value} -> {:error, {field, value}}
      nil -> {:ok, pos}
    end
  end

  defp do_validate({nil, _, _}), do: {:blknum, :cannot_be_nil}
  defp do_validate({_, nil, _}), do: {:txindex, :cannot_be_nil}
  defp do_validate({_, _, nil}), do: {:oindex, :cannot_be_nil}

  defp do_validate({blknum, _, _}) when is_integer(blknum) and blknum > @max_blknum,
    do: {:blknum, :cannot_exceed_maximum_value}

  defp do_validate({_, txindex, _}) when is_integer(txindex) and txindex > @max_txindex,
    do: {:txindex, :cannot_exceed_maximum_value}

  defp do_validate({_, _, _}), do: nil

  defp pad_binary(unpadded) do
    pad_size = (32 - byte_size(unpadded)) * 8
    <<0::size(pad_size)>> <> unpadded
  end
end
