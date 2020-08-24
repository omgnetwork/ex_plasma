defmodule ExPlasma.Output.Position.Validator do
  @moduledoc """
  Contain stateless validation logic for position
  """

  alias ExPlasma.Output.Position

  @block_offset Position.block_offset()
  @transaction_offset Position.transaction_offset()

  @max_txindex :math.pow(2, 16) - 1
  @max_blknum (:math.pow(2, 54) - 1 - @max_txindex) / (@block_offset / @transaction_offset)

  @type blknum_validation_errors() ::
          {:blknum, :cannot_be_nil}
          | {:blknum, :cannot_exceed_maximum_value}
          | {:blknum, :must_be_an_integer}
  @type txindex_validation_errors() ::
          {:txindex, :cannot_be_nil}
          | {:txindex, :cannot_exceed_maximum_value}
          | {:txindex, :must_be_an_integer}
  @type oindex_validation_errors() :: {:oindex, :cannot_be_nil} | {:oindex, :must_be_an_integer}

  @spec validate_blknum(pos_integer()) :: :ok | {:error, blknum_validation_errors()}
  def validate_blknum(nil), do: {:error, {:blknum, :cannot_be_nil}}

  def validate_blknum(blknum) when is_integer(blknum) and blknum > @max_blknum do
    {:error, {:blknum, :cannot_exceed_maximum_value}}
  end

  def validate_blknum(blknum) when is_integer(blknum), do: :ok
  def validate_blknum(_blknum), do: {:error, {:blknum, :must_be_an_integer}}

  @spec validate_txindex(non_neg_integer()) :: :ok | {:error, txindex_validation_errors()}
  def validate_txindex(nil), do: {:error, {:txindex, :cannot_be_nil}}

  def validate_txindex(txindex) when is_integer(txindex) and txindex > @max_txindex do
    {:error, {:txindex, :cannot_exceed_maximum_value}}
  end

  def validate_txindex(txindex) when is_integer(txindex), do: :ok
  def validate_txindex(_txindex), do: {:error, {:txindex, :must_be_an_integer}}

  @spec validate_oindex(non_neg_integer()) :: :ok | {:error, oindex_validation_errors()}
  def validate_oindex(nil), do: {:error, {:oindex, :cannot_be_nil}}
  def validate_oindex(oindex) when is_integer(oindex), do: :ok
  def validate_oindex(_oindex), do: {:error, {:oindex, :must_be_an_integer}}
end
