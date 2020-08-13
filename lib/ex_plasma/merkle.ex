defmodule ExPlasma.Merkle do
  @moduledoc """
  Encapsulates all the interactions with the MerkleTree library.
  """

  alias ExPlasma.Crypto

  @transaction_merkle_tree_height 16
  @default_leaf <<0::256>>

  @doc """
  Generate a Merkle Root hash for the given list of transactions in encoded byte form.

  ## Examples

    iex> txns = %ExPlasma.Transaction{tx_type: 1} |> ExPlasma.encode(signed: false) |> List.wrap()
    iex> ExPlasma.Merkle.root_hash(txns)
    <<168, 54, 172, 201, 1, 212, 18, 167, 34, 57, 232, 89, 151, 225, 172, 150, 208,
      77, 194, 12, 174, 250, 146, 254, 93, 42, 28, 253, 203, 237, 247, 62>>
  """
  @spec root_hash([binary(), ...]) :: binary()
  def root_hash(encoded_transactions) do
    MerkleTree.fast_root(encoded_transactions,
      hash_function: &Crypto.keccak_hash/1,
      height: @transaction_merkle_tree_height,
      default_data_block: @default_leaf
    )
  end

  # Creates a Merkle proof that transaction under a given transaction index
  # is included in block consisting of hashed transactions
  @spec proof([binary(), ...], non_neg_integer()) :: binary()
  def proof(encoded_transactions, txindex) do
    encoded_transactions
    |> build()
    |> prove(txindex)
    |> Enum.reverse()
    |> Enum.join()
  end

  defp build(encoded_transactions) do
    MerkleTree.build(encoded_transactions,
      hash_function: &Crypto.keccak_hash/1,
      height: @transaction_merkle_tree_height,
      default_data_block: @default_leaf
    )
  end

  defp prove(hash, txindex) do
    MerkleTree.Proof.prove(hash, txindex)
  end
end
