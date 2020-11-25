defmodule ExPlasma.Encoding do
  @moduledoc """
  Provides the common encoding functionality we use across
  all the transactions and clients.
  """

  @doc """
  Converts binary and integer values into its hex string
  equivalent.

  ## Examples

      # Convert a raw binary to hex
      iex> raw = <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
      iex> ExPlasma.Encoding.to_hex(raw)
      "0x1df62f291b2e969fb0849d99d9ce41e2f137006e"

      # Convert an integer to hex
      iex> ExPlasma.Encoding.to_hex(1)
      "0x1"
  """
  @spec to_hex(binary | non_neg_integer) :: String.t()
  def to_hex(non_hex)
  def to_hex(raw) when is_binary(raw), do: "0x" <> Base.encode16(raw, case: :lower)
  def to_hex(int) when is_integer(int), do: "0x" <> Integer.to_string(int, 16)

  @doc """
  Converts a hex string into the integer value.

  ## Examples

      # Convert a hex string into an integer
      iex> ExPlasma.Encoding.to_int("0xb")
      11

      # Convert a binary into an integer
      iex> ExPlasma.Encoding.to_int(<<11>>)
      11
  """
  @spec to_int(String.t()) :: non_neg_integer
  def to_int("0x" <> encoded) do
    {return, ""} = Integer.parse(encoded, 16)
    return
  end

  def to_int(encoded) when is_binary(encoded), do: :binary.decode_unsigned(encoded, :big)

  @doc """
  Converts a hex string into a binary.

  ## Examples

      iex> ExPlasma.Encoding.to_binary("0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e")
      {:ok, <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
        55, 0, 110>>}
  """
  @spec to_binary(String.t()) :: {:ok, binary} | {:error, :decoding_error}
  def to_binary("0x" <> unprefixed_hex) do
    case unprefixed_hex |> String.upcase() |> Base.decode16() do
      {:ok, binary} -> {:ok, binary}
      :error -> {:error, :decoding_error}
    end
  end

  @doc """
  Throwing version of to_binary/1

  ## Examples

      iex> ExPlasma.Encoding.to_binary!("0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e")
      <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
        55, 0, 110>>
  """
  @spec to_binary!(String.t()) :: binary | no_return()
  def to_binary!("0x" <> _unprefixed_hex = prefixed_hex) do
    {:ok, binary} = to_binary(prefixed_hex)

    binary
  end
end
