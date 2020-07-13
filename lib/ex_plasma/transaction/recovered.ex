defmodule ExPlasma.Transaction.Recovered do
  @moduledoc """
  Representation of a signed transaction, with addresses recovered from signatures (from `ExPlasma.Transaction.Signed`)
  """

  alias ExPlasma.Crypto
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.Witness

  @type tx_bytes() :: binary()
  @type tx_hash() :: Crypto.hash_t()
  @type decoding_error() :: Signed.decoding_error()
  @type validation_error() :: Signed.validation_error()

  @type t() :: %__MODULE__{
          tx_hash: tx_hash(),
          witnesses: list(Witness.t()),
          signed_tx: Signed.t(),
          signed_tx_bytes: tx_bytes()
        }

  defstruct [:signed_tx, :tx_hash, :signed_tx_bytes, :witnesses]

  @doc """
  Similar to Signed.decode/1 but also recovers the witnesses and transaction hash.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec decode(tx_bytes()) :: {:ok, t()} | {:error, decoding_error()}
  def decode(encoded_signed_tx) do
    with {:ok, signed_tx} <- Signed.decode(encoded_signed_tx),
         {:ok, witnesses} <- Signed.get_witnesses(signed_tx) do
      {:ok,
       %__MODULE__{
         tx_hash: Transaction.hash(signed_tx),
         witnesses: witnesses,
         signed_tx: signed_tx,
         signed_tx_bytes: encoded_signed_tx
       }}
    end
  end

  @spec validate(t()) :: :ok | {:error, validation_error()}
  def validate(%__MODULE__{} = recovered), do: Signed.validate(recovered.signed_tx)
end
