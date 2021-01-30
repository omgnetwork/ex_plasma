defmodule ExPlasma.InFlightExit do
  @moduledoc """
  Represents an in-flight exit (IFE).
  """
  use Bitwise, only_operators: true

  alias ExPlasma.Crypto

  @doc """
  Derive the in-flight exit ID from its transaction bytes.

  See https://github.com/omisego/plasma-contracts/blob/v1.0.3/plasma_framework/contracts/src/exits/utils/ExitId.sol#L53-L55
  """
  @spec tx_bytes_to_id(binary()) :: pos_integer()
  def tx_bytes_to_id(tx_bytes) do
    tx_bytes
    |> Crypto.keccak_hash()
    |> :binary.decode_unsigned()
    |> Bitwise.>>>(get_bit_shift_size())
    |> set_bit(get_set_bit())
  end

  defp set_bit(data, bit_position) do
    data ||| 1 <<< bit_position
  end

  defp get_bit_shift_size() do
    case ExPlasma.Configuration.exit_id_size() do
      160 -> 105
      168 -> 89
    end
  end

  defp get_set_bit() do
    case ExPlasma.Configuration.exit_id_size() do
      160 -> 151
      168 -> 167
    end
  end
end
