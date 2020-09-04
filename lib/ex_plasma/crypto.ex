defmodule ExPlasma.Crypto do
  @moduledoc """
  Signs and validates signatures. Constructed signatures can be used directly
  in Ethereum with `ecrecover` call.
  """
  alias ExPlasma.Signature

  @type sig_t() :: <<_::520>>
  @type pub_key_t() :: <<_::512>>
  @type address_t() :: <<_::160>>
  @type hash_t() :: <<_::256>>

  @type recover_address_error() :: :corrupted_witness | :invalid_message

  @doc """
  Produces a KECCAK digest for the message.

  ## Example

    iex> ExPlasma.Crypto.keccak_hash("omg!")
    <<241, 85, 204, 147, 187, 239, 139, 133, 69, 248, 239, 233, 219, 51, 189, 54,
      171, 76, 106, 229, 69, 102, 203, 7, 21, 134, 230, 92, 23, 209, 187, 12>>
  """
  @spec keccak_hash(binary()) :: hash_t()
  def keccak_hash(message) do
    {:ok, hash} = ExKeccak.hash_256(message)

    hash
  end

  @doc """
  Recovers the address of the signer from a binary-encoded signature.
  """
  @spec recover_address(hash_t(), sig_t()) :: {:ok, address_t()} | {:error, recover_address_error()}
  def recover_address(<<digest::binary-size(32)>>, <<packed_signature::binary-size(65)>>) do
    case Signature.recover_public(digest, packed_signature) do
      {:ok, pub} ->
        generate_address(pub)

      {:error, _} ->
        {:error, :corrupted_witness}
    end
  end

  def recover_address(<<_digest::binary-size(32)>>, _signature), do: {:error, :corrupted_witness}

  def recover_address(_message, _signature), do: {:error, :invalid_message}

  @doc """
  Given public key, returns an address.
  """
  @spec generate_address(pub_key_t()) :: {:ok, address_t()}
  def generate_address(<<pub::binary-size(64)>>) do
    <<_::binary-size(12), address::binary-size(20)>> = keccak_hash(pub)
    {:ok, address}
  end
end
