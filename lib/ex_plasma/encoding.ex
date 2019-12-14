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
  @spec merkle_proof(list(binary()), non_neg_integer()) :: binary()
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

    iex> encoded_txns = [%ExPlasma.Transaction{} |> ExPlasma.Transaction.encode()]
    iex> ExPlasma.Encoding.merkle_root_hash(encoded_txns)
    <<149, 220, 232, 195, 129, 97, 40, 191, 35, 233, 11, 119, 125, 93, 233, 214, 60,
      13, 243, 24, 176, 181, 34, 87, 196, 98, 131, 152, 57, 231, 240, 184>>
  """
  @spec merkle_root_hash(list(binary())) :: binary()
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

  iex> ExPlasma.Encoding.to_int("0xb")
  11
  """
  @spec to_int(String.t()) :: non_neg_integer
  def to_int("0x" <> encoded) do
    {return, ""} = Integer.parse(encoded, 16)
    return
  end

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

  @doc """
  Produces a stand-alone, 65 bytes long, signature for message hash.
  """
  @spec signature_digest(<<_::256>>, <<_::256>>) :: <<_::520>>
  def signature_digest(hash_digest, private_key_hash) do
    private_key_binary = to_binary(private_key_hash)

    {:ok, <<r::size(256), s::size(256)>>, recovery_id} =
      :libsecp256k1.ecdsa_sign_compact(
        hash_digest,
        private_key_binary,
        :default,
        <<>>
      )

    # EIP-155
    # See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
    base_recovery_id = 27
    recovery_id = base_recovery_id + recovery_id

    <<r::integer-size(256), s::integer-size(256), recovery_id::integer-size(8)>>
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
