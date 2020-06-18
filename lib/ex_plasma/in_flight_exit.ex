defmodule ExPlasma.InFlightExit do
  @moduledoc """
  Represents an in-flight exit (IFE).
  """
  use Bitwise, only_operators: true

  @doc """
  Derive the in-flight exit ID from its transaction bytes.

  See https://github.com/omisego/plasma-contracts/blob/v1.0.3/plasma_framework/contracts/src/exits/utils/ExitId.sol#L53-L55
  """
  @spec txbytes_to_id(binary()) :: pos_integer()
  def txbytes_to_id(txbytes) do
    txbytes
    |> ExPlasma.Encoding.keccak_hash()
    |> :binary.decode_unsigned()
    |> Bitwise.>>>(89)
    |> set_bit(167)
  end

  defp set_bit(data, bit_position) do
    data ||| 1 <<< bit_position
  end
end
