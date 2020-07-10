defmodule ExPlasma.Transaction.Signed do
  @moduledoc """
  Representation of a signed transaction.

  NOTE: before you use this, make sure you shouldn't use `Transaction` or `Transaction.Recovered`
  """

  alias ExPlasma.Crypto
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Protocol
  alias ExPlasma.Transaction.Witness
  alias ExPlasma.TypedData

  @type tx_bytes() :: binary()

  defstruct [:raw_tx, :sigs]

  @type t() :: %__MODULE__{
          raw_tx: Protocol.t(),
          sigs: [Crypto.sig_t()]
        }

  @doc """
  Produce a binary form of a signed transaction - coerces into RLP-encodeable structure and RLP encodes
  """
  @spec encode(t()) :: tx_bytes()
  def encode(%__MODULE__{raw_tx: %{} = raw_tx, sigs: sigs}) do
    rlp = [sigs | Protocol.to_rlp(raw_tx)]
    ExRLP.encode(rlp)
  end

  @doc """
  Produces a struct from the binary encoded form of a signed transactions - RLP decodes to structure of RLP-items
  and then produces an Elixir struct.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec decode(tx_bytes()) :: {:ok, t()} | {:error, atom}
  def decode(signed_tx_bytes) do
    with {:ok, tx_rlp_decoded_chunks} <- try_generic_decode(signed_tx_bytes) do
      to_map(tx_rlp_decoded_chunks)
    end
  end

  defp try_generic_decode(signed_tx_bytes) do
    {:ok, ExRLP.decode(signed_tx_bytes)}
  rescue
    _ -> {:error, :malformed_transaction_rlp}
  end

  @doc """
  Decodes an RLP list into a Signed Transaction.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  def to_map([sigs | typed_tx_rlp_decoded_chunks]) do
    with :ok <- validate_sigs_list(sigs),
         {:ok, raw_tx} <- Transaction.to_map(typed_tx_rlp_decoded_chunks),
         do: {:ok, %__MODULE__{raw_tx: raw_tx, sigs: sigs}}
  end

  def to_map(_), do: {:error, :malformed_transaction}

  defp validate_sigs_list(sigs) when is_list(sigs), do: :ok
  defp validate_sigs_list(_sigs), do: {:error, :malformed_witnesses}

  @doc """
  Validate a signed transaction.
  """
  @spec validate(t()) :: {:ok, t()} | {:error, atom()}
  def validate(%__MODULE__{} = transaction) do
    with :ok <- validate_sigs(transaction.sigs),
         {:ok, _} <- Protocol.validate(transaction.raw_tx) do
      {:ok, transaction}
    end
  end

  defp validate_sigs([sig | rest]) do
    with true <- Witness.valid?(sig) || {:error, :malformed_witnesses}, do: validate_sigs(rest)
  end

  defp validate_sigs([]), do: :ok

  @doc """
  Recovers the witnesses for non-empty signatures, in the order they appear in transaction's signatures
  """
  @spec get_witnesses(t()) ::
          {:ok, list(Witness.t())} | {:error, atom}
  def get_witnesses(%__MODULE__{sigs: []}), do: {:ok, []}

  def get_witnesses(%__MODULE__{} = signed) do
    %__MODULE__{raw_tx: raw_tx, sigs: sigs} = signed
    hash = TypedData.hash(raw_tx)

    sigs
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
end
