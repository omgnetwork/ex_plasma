defmodule ExPlasma.Transaction do
  @moduledoc """
  This module contains the public Transaction API to be prefered to access data of different transaction "flavors",
  like `Transaction.Signed` or `Transaction.Recovered`
  """

  alias ExPlasma.Crypto
  alias ExPlasma.Output
  alias ExPlasma.Signature
  alias ExPlasma.Transaction.Protocol
  alias ExPlasma.Transaction.Recovered
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.TypeMapper
  alias ExPlasma.TypedData
  alias ExPlasma.Utils.RlpDecoder

  @tx_types_modules TypeMapper.tx_type_modules()
  @tx_types Map.keys(@tx_types_modules)

  @type any_flavor_t() :: Signed.t() | Recovered.t() | Protocol.t()

  @type tx_bytes() :: binary()
  @type tx_hash() :: Crypto.hash_t()

  @type decoding_error() ::
          :malformed_rlp
          | mapping_error()

  @type mapping_error() ::
          :malformed_transaction
          | :unrecognized_transaction_type
          | atom()

  @doc """
  Attempt to decode the given transaction bytes into an Elixir structure.

  First, decodes the bytes into an RLP list of items.
  Then, depending on the value
  of the `mode` params, will map the values to one of the following structures:

  - `:recovered` -> Recovered transaction
  - `:signed` -> Signed transaction
  - `:raw` or ommited -> Raw transaction

  Only validates that the RLP is structurally correct and that the tx type is supported.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec decode(tx_bytes(), :recovered | :signed | :raw) :: {:ok, any_flavor_t()} | {:error, decoding_error()}
  def decode(tx_bytes, mode \\ :raw)

  def decode(tx_bytes, :recovered), do: Recovered.decode(tx_bytes)
  def decode(tx_bytes, :signed), do: Signed.decode(tx_bytes)

  def decode(tx_bytes, :raw) do
    with {:ok, raw_tx_rlp_decoded_chunks} <- RlpDecoder.decode(tx_bytes) do
      to_map(raw_tx_rlp_decoded_chunks)
    end
  end

  @doc """
  RLP decodes to structure of RLP-items and then produces an Elixir struct.

  Assume that it represents a raw transaction if it starts with an integer representing the type.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec to_map(list()) :: {:ok, Protocol.t()} | {:error, mapping_error()}
  def to_map([raw_tx_type | raw_tx_rlp_decoded_chunks]) do
    with {:ok, tx_type} <- parse_tx_type(raw_tx_type) do
      protocol_module = @tx_types_modules[tx_type]
      Protocol.to_map(protocol_module.__struct__, [raw_tx_type | raw_tx_rlp_decoded_chunks])
    end
  end

  def to_map(_), do: {:error, :malformed_transaction}

  defp parse_tx_type(tx_type_rlp) do
    case RlpDecoder.parse_uint256(tx_type_rlp) do
      {:ok, tx_type} when tx_type in @tx_types -> {:ok, tx_type}
      _ -> {:error, :unrecognized_transaction_type}
    end
  end

  @doc """
  Signs the inputs of the transaction with the given keys in the corresponding order.
  Only signs transactions that implement the ExPlasma.TypedData protocol.

  Returns
  - {:ok, %Explasma.Signed{}} when succesfuly signed
  or
  - {:error, :not_signable} when the given transaction is not supported.

  ## Example

  iex> key = "0x79298b0292bbfa9b15705c56b6133201c62b798f102d7d096d31d7637f9b2382"
  iex> txn = %ExPlasma.Transaction.Type.PaymentV1.new([], [])
  iex> ExPlasma.Transaction.sign(txn, keys: [key])
  %ExPlasma.Transaction.Signed{
    sigs: [
          <<129, 213, 32, 15, 183, 218, 255, 22, 82, 95, 22, 86, 103, 227, 92, 109, 9,
            89, 7, 142, 235, 107, 203, 29, 20, 231, 91, 168, 255, 119, 204, 239, 44,
            125, 76, 109, 200, 196, 204, 230, 224, 241, 84, 75, 9, 3, 160, 177, 37,
            181, 174, 98, 51, 15, 136, 235, 47, 96, 15, 209, 45, 85, 153, 2, 28>>
        ],
    raw_tx: %{
      inputs: [],
      metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      outputs: [],
      tx_data: 0
    }
  }
  """
  @spec sign(TypedData.t(), keys: list(String.t())) :: {:ok, Signed.t()} | {:error, :not_signable}
  def sign(%{} = raw_tx, keys: keys) when is_list(keys) do
    case TypedData.impl_for(raw_tx) do
      nil ->
        {:error, :not_signable}

      _ ->
        eip712_hash = TypedData.hash(raw_tx)
        sigs = Enum.map(keys, fn key -> Signature.signature_digest(eip712_hash, key) end)
        {:ok, %Signed{raw_tx: raw_tx, sigs: sigs}}
    end
  end

  @doc """
  Returns all inputs of the raw transaction involved, never returns zero inputs
  """
  @spec get_inputs(any_flavor_t()) :: list(Output.t())
  def get_inputs(%Recovered{} = recovered), do: get_inputs(recovered.signed_tx)
  def get_inputs(%Signed{} = signed), do: get_inputs(signed.raw_tx)
  def get_inputs(%{} = raw_tx), do: Protocol.get_inputs(raw_tx)

  @doc """
  Returns all outputs of the raw transaction involved, never returns zero outputs
  """
  @spec get_outputs(any_flavor_t()) :: list(Output.t())
  def get_outputs(%Recovered{} = recovered), do: get_outputs(recovered.signed_tx)
  def get_outputs(%Signed{} = signed), do: get_outputs(signed.raw_tx)
  def get_outputs(%{} = raw_tx), do: Protocol.get_outputs(raw_tx)

  @doc """
  Returns the type of the raw transaction involved
  """
  @spec get_tx_type(any_flavor_t()) :: pos_integer()
  def get_tx_type(%Recovered{} = recovered), do: get_tx_type(recovered.signed_tx)
  def get_tx_type(%Signed{} = signed), do: get_tx_type(signed.raw_tx)
  def get_tx_type(%{} = raw_tx), do: Protocol.get_tx_type(raw_tx)

  @doc """
  Returns the encoded bytes of the transaction
  If it's a `Signed` or `Recovered` transaction, encode with the signatures
  If it's a raw transaction, encodes it without the signatures
  """
  @spec encode(any_flavor_t()) :: tx_bytes()
  def encode(%Recovered{} = recovered), do: encode(recovered.signed_tx)
  def encode(%Signed{} = signed), do: Signed.encode(signed)
  def encode(%{} = raw_tx), do: raw_tx |> Protocol.to_rlp() |> ExRLP.encode()

  @doc """
  Returns the hash of the raw transaction involved without the signatures
  """
  @spec hash(any_flavor_t()) :: tx_hash()
  def hash(%Recovered{} = recovered), do: recovered.tx_hash
  def hash(%Signed{} = signed), do: hash(signed.raw_tx)
  def hash(%{} = raw_tx), do: raw_tx |> encode() |> hash()
  def hash(tx) when is_binary(tx), do: Crypto.keccak_hash(tx)

  @doc """
  Validates the transaction in its flavor context.

  For a Recovered transaction: validates the signed transaction
  For a Signed transaction: validates the signed transaction
  For a Raw transaction: validates the raw transaction

  Returns :ok if valid or {:error, {atom, atom}} otherwise
  """
  @spec validate(any_flavor_t()) :: :ok | {:error, {atom(), atom()}}
  def validate(%Recovered{} = recovered), do: Recovered.validate(recovered)
  def validate(%Signed{} = signed), do: Signed.validate(signed)
  def validate(%{} = raw_tx), do: Protocol.validate(raw_tx)
end
