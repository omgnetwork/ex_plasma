defmodule ExPlasma.Utils.RlpDecoder do
  @moduledoc """
  Provides functions to decode various data types from RLP raw format
  """

  alias ExPlasma.Crypto

  @type parse_uint256_errors() :: :encoded_uint_too_big | :malformed_uint256

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
  Parses 20-bytes address
  Case `<<>>` is necessary, because RLP handles empty string equally to integer 0
  """
  @spec parse_address(<<>> | Crypto.address_t()) :: {:ok, Crypto.address_t()} | {:error, :malformed_address}
  def parse_address(binary)
  def parse_address(<<_::160>> = address_bytes), do: {:ok, address_bytes}
  def parse_address(_), do: {:error, :malformed_address}

  @doc """
  Parses unsigned at-most 32-bytes integer. Leading zeros are disallowed
  """
  @spec parse_uint256(binary()) ::
          {:ok, non_neg_integer()} | {:error, parse_uint256_errors() | :leading_zeros_in_encoded_uint}
  def parse_uint256(<<0>>), do: {:ok, 0}
  def parse_uint256(<<0>> <> _binary), do: {:error, :leading_zeros_in_encoded_uint}
  def parse_uint256(binary), do: parse_uint256_with_leading(binary)

  @doc """
  Parses unsigned at-most 32-bytes integer. Leading zeros are allowed
  """
  @spec parse_uint256_with_leading(binary()) :: {:ok, non_neg_integer()} | {:error, parse_uint256_errors()}
  def parse_uint256_with_leading(binary) when byte_size(binary) <= 32, do: {:ok, :binary.decode_unsigned(binary, :big)}
  def parse_uint256_with_leading(binary) when byte_size(binary) > 32, do: {:error, :encoded_uint_too_big}
  def parse_uint256_with_leading(_), do: {:error, :malformed_uint256}
end
