# Copyright 2019-2020 OmiseGO Pte Ltd
defmodule ExPlasma.Utils.RlpDecoder do
  @moduledoc """
  Provides functions to decode various data types from RLP raw format
  """

  @doc """
  Parses unsigned at-most 32-bytes integer. Leading zeros are disallowed
  """
  @spec parse_uint256(binary()) ::
          {:ok, non_neg_integer()} | {:error, :encoded_uint_too_big | :leading_zeros_in_encoded_uint}
  def parse_uint256(<<0>> <> _binary), do: {:error, :leading_zeros_in_encoded_uint}
  def parse_uint256(binary) when byte_size(binary) <= 32, do: {:ok, :binary.decode_unsigned(binary, :big)}
  def parse_uint256(binary) when byte_size(binary) > 32, do: {:error, :encoded_uint_too_big}
  def parse_uint256(_), do: {:error, :malformed_uint256}
end
