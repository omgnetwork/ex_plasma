defmodule ExPlasma.Encoding do
  @moduledoc """
  Provides the common encoding functionality we use across
  all the transactions and clients.
  """

  @type hash_t() :: <<_::256>>

  @transaction_merkle_tree_height 16
  @default_leaf <<0::256>>

  @doc """
  Produces a KECCAK digest for the message.

  see https://hexdocs.pm/exth_crypto/ExthCrypto.Hash.html#kec/0

  ## Example

    iex> ExPlasma.Encoding.keccak_hash("omg!")
    <<241, 85, 204, 147, 187, 239, 139, 133, 69, 248, 239, 233, 219, 51, 189, 54,
      171, 76, 106, 229, 69, 102, 203, 7, 21, 134, 230, 92, 23, 209, 187, 12>>
  """
  @spec keccak_hash(binary()) :: hash_t()
  def keccak_hash(message), do: ExthCrypto.Hash.hash(message, ExthCrypto.Hash.kec())

  # Creates a Merkle proof that transaction under a given transaction index
  # is included in block consisting of hashed transactions
  @spec merkle_proof([binary(), ...], non_neg_integer()) :: binary()
  def merkle_proof(encoded_transactions, txindex) do
    encoded_transactions
    |> build()
    |> prove(txindex)
    |> Enum.reverse()
    |> Enum.join()
  end

  @doc """
  Generate a Merkle Root hash for the given list of transactions in encoded byte form.

  ## Examples

    iex> txns = %ExPlasma.Transaction{tx_type: 1} |> ExPlasma.encode() |> List.wrap()
    iex> ExPlasma.Encoding.merkle_root_hash(txns)
    <<168, 54, 172, 201, 1, 212, 18, 167, 34, 57, 232, 89, 151, 225, 172, 150, 208,
      77, 194, 12, 174, 250, 146, 254, 93, 42, 28, 253, 203, 237, 247, 62>>
  """
  @spec merkle_root_hash([binary(), ...]) :: binary()
  def merkle_root_hash(encoded_transactions) do
    MerkleTree.fast_root(encoded_transactions,
      hash_function: &keccak_hash/1,
      height: @transaction_merkle_tree_height,
      default_data_block: @default_leaf
    )
  end

  @doc """
  Converts binary and integer values into its hex string
  equivalent.

  ## Examples

    Convert a raw binary to hex
    iex> raw = <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
    iex> ExPlasma.Encoding.to_hex(raw)
    "0x1df62f291b2e969fb0849d99d9ce41e2f137006e"

    Convert an integer to hex
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

    iex> ExPlasma.Encoding.to_binary "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
      55, 0, 110>>
  """
  @spec to_binary(String.t()) :: binary
  def to_binary("0x" <> unprefixed_hex) do
    {:ok, binary} =
      unprefixed_hex
      |> String.upcase()
      |> Base.decode16()

    binary
  end

  defp build(encoded_transactions) do
    MerkleTree.build(encoded_transactions,
      hash_function: &keccak_hash/1,
      height: @transaction_merkle_tree_height,
      default_data_block: @default_leaf
    )
  end

  defp prove(hash, txindex) do
    MerkleTree.Proof.prove(hash, txindex)
  end
end
