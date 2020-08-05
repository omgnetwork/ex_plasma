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
  alias ExPlasma.Utils.RlpDecoder

  @type tx_bytes() :: binary()
  @type decoding_error() :: :malformed_rlp | mapping_error()

  @type mapping_error() ::
          :malformed_transaction
          | :malformed_witnesses
          | atom()

  @type validation_error() :: {:witnesses, :malformed_witnesses} | {atom(), atom()}

  @type t() :: %__MODULE__{
          raw_tx: Protocol.t(),
          sigs: [Crypto.sig_t()]
        }

  defstruct [:raw_tx, :sigs]

  @doc """
  Produce a binary form of a signed transaction - coerces into RLP-encodeable structure and RLP encodes
  """
  @spec encode(t()) :: tx_bytes()
  def encode(%__MODULE__{} = signed) do
    signed |> to_rlp() |> ExRLP.encode()
  end

  @doc """
  RLP encodes the signed transaction.
  """
  @spec to_rlp(t()) :: list()
  def to_rlp(%__MODULE__{} = signed) do
    [signed.sigs | Protocol.to_rlp(signed.raw_tx)]
  end

  @doc """
  Produces a struct from the binary encoded form of a signed transactions - RLP decodes to structure of RLP-items
  and then produces an Elixir struct.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec decode(tx_bytes()) :: {:ok, t()} | {:error, decoding_error()}
  def decode(signed_tx_bytes) do
    case RlpDecoder.decode(signed_tx_bytes) do
      {:ok, tx_rlp_decoded_chunks} ->
        to_map(tx_rlp_decoded_chunks)

      error ->
        error
    end
  end

  @doc """
  Decodes an RLP list into a Signed Transaction.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec to_map(list()) :: {:ok, t()} | {:error, mapping_error()}
  def to_map([sigs | typed_tx_rlp_decoded_chunks]) do
    with :ok <- validate_sigs_list(sigs),
         {:ok, raw_tx} <- Transaction.to_map(typed_tx_rlp_decoded_chunks),
         do: {:ok, %__MODULE__{raw_tx: raw_tx, sigs: sigs}}
  end

  def to_map(_), do: {:error, :malformed_transaction}

  @doc """
  Validate a signed transaction.

  Returns :ok if valid or {:error, atom()} otherwise.
  """
  @spec validate(t()) :: :ok | {:error, validation_error()}
  def validate(%__MODULE__{} = transaction) do
    with :ok <- validate_sigs(transaction.sigs),
         :ok <- Protocol.validate(transaction.raw_tx) do
      :ok
    end
  end

  @doc """
  Recovers the witnesses for non-empty signatures, in the order they appear in transaction's signatures.

  Returns {:ok, witness_list} if witnesses are recoverable,
  or {:error, :corrupted_witness} otherwise.
  """
  @spec get_witnesses(t()) :: {:ok, list(Witness.t())} | {:error, Witness.recovery_error()}
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

  defp validate_sigs_list(sigs) when is_list(sigs), do: :ok
  defp validate_sigs_list(_sigs), do: {:error, :malformed_witnesses}

  defp validate_sigs([sig | rest]) do
    case Witness.valid?(sig) do
      true -> validate_sigs(rest)
      false -> {:error, {:witnesses, :malformed_witnesses}}
    end
  end

  defp validate_sigs([]), do: :ok
end
