defmodule ExPlasma.Transaction.Input do
  @moduledoc """
  An Input is an unspent output used in a transaction to generate a new
  unspent output.
  """

  @type t :: %__MODULE__{
          blknum: non_neg_integer(),
          txindex: non_neg_integer(),
          oindex: non_neg_integer()
        }

  defstruct blknum: 0, txindex: 0, oindex: 0

  @doc """
  Converts a given Input into an RLP-encodable list.

  ## Examples

  iex> output = %ExPlasma.Transaction.Input{blknum: 1, txindex: 2, oindex: 3}
  iex> ExPlasma.Transaction.Input.to_list(output)
  [1, 2, 3]
  """
  @spec to_list(__MODULE__.t() | map()) :: list()
  def to_list(%__MODULE__{} = input), do: input |> Map.from_struct() |> to_list()

  def to_list(%{blknum: blknum, txindex: txindex, oindex: oindex})
      when is_integer(blknum) and is_integer(txindex) and is_integer(oindex),
      do: [blknum, txindex, oindex]
end
