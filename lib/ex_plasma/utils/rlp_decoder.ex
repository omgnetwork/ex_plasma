defmodule ExPlasma.Utils.RlpDecoder do
  @moduledoc """
  Provides functions to decode various data types from RLP raw format
  """

  @type parse_uint256_errors() :: :leading_zeros_in_encoded_uint | :encoded_uint_too_big | :malformed_uint256

  @doc """
  Attempt to decode the given binary to a list of RLP items
  """
  @spec decode(binary()) :: {:ok, list()} | {:error, :malformed_rlp}
  def decode(tx_bytes) do
    {:ok, ExRLP.decode(tx_bytes)}
  rescue
    _ -> {:error, :malformed_rlp}
  end

  @doc """
  Parses unsigned at-most 32-bytes integer. Leading zeros are disallowed
  """
  @spec parse_uint256(binary()) :: {:ok, non_neg_integer()} | {:error, parse_uint256_errors()}
  def parse_uint256(<<0>>), do: {:ok, 0}
  def parse_uint256(<<0>> <> _binary), do: {:error, :leading_zeros_in_encoded_uint}
  def parse_uint256(binary) when byte_size(binary) <= 32, do: {:ok, :binary.decode_unsigned(binary, :big)}
  def parse_uint256(binary) when byte_size(binary) > 32, do: {:error, :encoded_uint_too_big}
  def parse_uint256(_), do: {:error, :malformed_uint256}
end
