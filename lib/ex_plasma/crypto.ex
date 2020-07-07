defmodule ExPlasma.Crypto do
  @moduledoc """
  Signs and validates signatures. Constructed signatures can be used directly
  in Ethereum with `ecrecover` call.
  """
  alias ExPlasma.Encoding
  alias ExPlasma.Signature

  @type sig_t() :: <<_::520>>
  @type pub_key_t() :: <<_::512>>
  @type address_t() :: <<_::160>>
  @type hash_t() :: <<_::256>>

  @doc """
  Recovers the address of the signer from a binary-encoded signature.
  """
  @spec recover_address(hash_t(), sig_t()) :: {:ok, address_t()} | {:error, :signature_corrupt | binary}
  def recover_address(<<digest::binary-size(32)>>, <<packed_signature::binary-size(65)>>) do
    case Signature.recover_public(digest, packed_signature) do
      {:ok, pub} ->
        generate_address(pub)

      {:error, "Recovery id invalid 0-3"} ->
        {:error, :signature_corrupt}

      other ->
        other
    end
  end

  def recover_address(<<_digest::binary-size(32)>>, _signature), do: {:error, :invalid_signature}

  def recover_address(_message, _signature), do: {:error, :invalid_message}

  @doc """
  Given public key, returns an address.
  """
  @spec generate_address(pub_key_t()) :: {:ok, address_t()}
  def generate_address(<<pub::binary-size(64)>>) do
    <<_::binary-size(12), address::binary-size(20)>> = Encoding.keccak_hash(pub)
    {:ok, address}
  end
end
