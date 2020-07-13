defmodule ExPlasma.Transaction.Witness do
  @moduledoc """
  Code required to validate and recover raw witnesses (e.g. signatures) goes here.
  """

  alias ExPlasma.Crypto

  @signature_length 65

  @type t :: Crypto.address_t()
  @type recovery_error() :: :corrupted_signature

  @doc """
  Pre-check done after decoding to quickly assert whether the witness has one of valid forms
  """
  def valid?(witness) when is_binary(witness), do: has_valid_length?(witness)

  @doc """
  Prepares the witness to be quickly used in stateful validation
  """
  @spec recover(Crypto.hash_t(), Crypto.sig_t()) :: {:ok, Crypto.address_t()} | {:error, recovery_error()}
  def recover(raw_txhash, raw_witness) when is_binary(raw_witness) do
    Crypto.recover_address(raw_txhash, raw_witness)
  end

  defp has_valid_length?(sig) when byte_size(sig) == @signature_length, do: true
  defp has_valid_length?(_sig), do: false
end
