defmodule ExPlasma.Transaction.Signed do
  @moduledoc """
  Representation of a signed transaction.

  NOTE: before you use this, make sure you shouldn't use `Transaction` or `Transaction.Recovered`
  """

  alias ExPlasma.Crypto
  alias ExPlasma.Signature
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Witness
  alias ExPlasma.TypedData
  alias ExPlasma.Utils.RlpDecoder

  @type tx_bytes() :: binary()
  @type decoding_error() :: :malformed_rlp | :malformed_witnesses
  @type validation_error() :: {:witnesses, :malformed_witnesses}
  @type sigs() :: list(Crypto.sig_t()) | []

  @doc """
  Decodes a binary expecting it to represent a signed transactions with
  the signatures being the first element of the decoded RLP list.

  Returns {:ok, sigs, typed_tx_rlp_items} if the encoded RLP can be decoded,
  or {:error, atom} otherwise.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec decode(tx_bytes()) :: {:ok, list()} | {:error, decoding_error()}
  def decode(signed_tx_bytes) do
    with {:ok, tx_rlp_items} <- RlpDecoder.decode(signed_tx_bytes),
         {:ok, signed_tx_rlp_items} <- validate_rlp_items(tx_rlp_items) do
      {:ok, signed_tx_rlp_items}
    end
  end

  @doc """
  Validate a signed transaction.

  Returns :ok if valid or {:error, {:witnesses, :malformed_witnesses}} otherwise.
  """
  @spec validate(Transaction.t()) :: :ok | {:error, validation_error()}
  def validate(transaction), do: validate_sigs(transaction.sigs)

  @doc """
  Recovers the witnesses for non-empty signatures, in the order they appear in transaction's signatures.

  Returns {:ok, witness_list} if witnesses are recoverable,
  or {:error, :corrupted_witness} otherwise.
  """
  @spec get_witnesses(Transaction.t()) :: {:ok, list(Witness.t())} | {:error, Witness.recovery_error()}
  def get_witnesses(%Transaction{sigs: []}), do: {:ok, []}

  def get_witnesses(transaction) do
    hash = TypedData.hash(transaction)

    transaction.sigs
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, []}, fn signature, {:ok, addresses} ->
      case Witness.recover(hash, signature) do
        {:ok, address} ->
          {:cont, {:ok, [address | addresses]}}

        error ->
          {:halt, error}
      end
    end)
  end

  @spec compute_signatures(Transaction.t(), list(String.t())) :: {:ok, Signed.t()} | {:error, :not_signable}
  def compute_signatures(transaction, keys) when is_list(keys) do
    case TypedData.impl_for(transaction) do
      nil ->
        {:error, :not_signable}

      _ ->
        eip712_hash = TypedData.hash(transaction)
        sigs = Enum.map(keys, fn key -> Signature.signature_digest(eip712_hash, key) end)
        {:ok, sigs}
    end
  end

  defp validate_rlp_items([sigs | _typed_tx_rlp_items] = rlp) when is_list(sigs), do: {:ok, rlp}
  defp validate_rlp_items([_sigs | _typed_tx_rlp_items]), do: {:error, :malformed_witnesses}
  defp validate_rlp_items(_), do: {:error, :malformed_transaction}

  defp validate_sigs([sig | rest]) do
    case Witness.valid?(sig) do
      true -> validate_sigs(rest)
      false -> {:error, {:witnesses, :malformed_witnesses}}
    end
  end

  defp validate_sigs([]), do: :ok
end
