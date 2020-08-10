defmodule ExPlasma.Transaction do
  @moduledoc """
  """

  alias ExPlasma.Crypto
  alias ExPlasma.Output
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.TypeMapper
  alias ExPlasma.Transaction.Witness
  alias ExPlasma.Utils.RlpDecoder

  @tx_types_modules TypeMapper.tx_type_modules()

  @empty_metadata <<0::256>>
  @empty_tx_data 0

  @type tx_bytes() :: binary()
  @type tx_hash() :: Crypto.hash_t()
  @type outputs() :: list(Output.t()) | []
  @type metadata() :: <<_::256>> | nil

  @type decoding_error() ::
          :malformed_rlp
          | mapping_error()

  @type mapping_error() ::
          :malformed_transaction
          | :unrecognized_transaction_type
          | atom()

  @type t() :: %__MODULE__{
          sigs: Signed.sigs(),
          tx_type: pos_integer(),
          inputs: outputs(),
          outputs: outputs(),
          tx_data: any(),
          metadata: metadata(),
          witnesses: list(Witness.t())
        }

  @enforce_keys [:tx_type]
  defstruct [
    :tx_type,
    inputs: [],
    outputs: [],
    tx_data: @empty_tx_data,
    metadata: @empty_metadata,
    sigs: [],
    witnesses: []
  ]

  @callback to_map(any()) :: map()
  @callback to_rlp(map()) :: any()
  @callback validate(any()) :: {:ok, map()} | {:error, {atom(), atom()}}

  @doc """
  Encode the given Transaction into an RLP encodeable list.
  ## Example
    iex> txn =
    ...>  %ExPlasma.Transaction{
    ...>    inputs: [
    ...>      %ExPlasma.Output{
    ...>        output_data: nil,
    ...>        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
    ...>        output_type: nil
    ...>      }
    ...>    ],
    ...>    metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    ...>    outputs: [
    ...>      %ExPlasma.Output{
    ...>        output_data: %{
    ...>          amount: 1,
    ...>          output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153,
    ...>            217, 206, 65, 226, 241, 55, 0, 110>>,
    ...>          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206,
    ...>            65, 226, 241, 55, 0, 110>>
    ...>        },
    ...>        output_id: nil,
    ...>        output_type: 1
    ...>      }
    ...>    ],
    ...>    sigs: [],
    ...>    tx_data: <<0>>,
    ...>    tx_type: 1
    ...>  }
    iex> ExPlasma.Transaction.encode(txn)
    <<248, 104, 1, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 237, 1, 235, 148, 29, 246, 47,
      41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110,
      148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
      241, 55, 0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0>>
  """
  @spec encode(t()) :: tx_bytes()
  def encode(%__MODULE__{} = transaction), do: transaction |> to_rlp() |> encode()
  def encode(rlp_items) when is_list(rlp_items), do: ExRLP.encode(rlp_items)

  @doc """
  Attempt to decode the given RLP list into a Transaction.

  Only validates that the RLP is structurally correct and that the tx type is supported.
  Does not perform any other kind of validation, use validate/1 for that.

  ## Example
  iex> rlp = <<248, 74, 192, 1, 193, 128, 239, 174, 237, 1, 235, 148, 29, 246, 47, 41, 27,
  ...>   46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46,
  ...>   38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
  ...>   0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...>   0>>
  iex> ExPlasma.Transaction.decode(rlp)
  %ExPlasma.Transaction{
    inputs: [
      %ExPlasma.Output{
        output_data: nil,
        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
        output_type: nil
      }
    ],
    metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    outputs: [
      %ExPlasma.Output{
        output_data: %{
          amount: 1,
          output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153,
            217, 206, 65, 226, 241, 55, 0, 110>>,
          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206,
            65, 226, 241, 55, 0, 110>>
        },
        output_id: nil,
        output_type: 1
      }
    ],
    sigs: [],
    tx_data: 0,
    tx_type: 1
  }
  """
  @spec decode(tx_bytes()) :: {:ok, t()} | {:error, decoding_error()}
  def decode(tx_bytes) do
    with {:ok, signed_tx_rlp_items} <- Signed.decode(tx_bytes),
         {:ok, transaction} <- to_map(signed_tx_rlp_items) do
      {:ok, transaction}
    end
  end

  @doc """
  Maps the given RLP list into a transaction.

  When the RLP list starts with a list, assumes it's the sigs
  and map it accordingly.
  If not starting with a list, assumes it's the transaction type.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec to_map(list()) :: {:ok, t()} | {:error, mapping_error()}
  def to_map([sigs | typed_tx_rlp_items]) when is_list(sigs) do
    case to_map(typed_tx_rlp_items) do
      {:ok, transaction} -> {:ok, %{transaction | sigs: sigs}}
      {:error, _mapping_error} = error -> error
    end
  end

  def to_map([raw_tx_type | _transaction_rlp_items] = rlp) do
    with {:ok, _tx_type, transaction_module} <- parse_tx_type(raw_tx_type),
         {:ok, transaction} <- transaction_module.to_map(rlp) do
      {:ok, transaction}
    end
  end

  def to_map(_), do: {:error, :malformed_transaction}

  @spec to_rlp(t()) :: list()
  def to_rlp(transaction) do
    case get_transaction_module(transaction.tx_type) do
      {:ok, module} -> [transaction.sigs | module.to_rlp(transaction)]
      {:error, :unrecognized_transaction_type} = error -> error
    end
  end

  @spec with_witnesses(t()) :: {:ok, t()} | {:error, Witness.recovery_error()}
  def with_witnesses(transaction) do
    case Signed.get_witnesses(transaction) do
      {:ok, witnesses} -> {:ok, Map.put(transaction, :witnesses, witnesses)}
      {:error, _witness_recovery_error} = error -> error
    end
  end

  @doc """
  Statelessly validate a transation.

  ## Example
  iex> txn = %ExPlasma.Transaction{
  ...>  inputs: [
  ...>    %ExPlasma.Output{
  ...>      output_data: nil,
  ...>      output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
  ...>      output_type: nil
  ...>    }
  ...>  ],
  ...>  metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
  ...>  outputs: [
  ...>    %ExPlasma.Output{
  ...>      output_data: %{
  ...>        amount: <<0, 0, 0, 0, 0, 0, 0, 1>>,
  ...>        output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
  ...>        token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
  ...>      },
  ...>      output_id: nil,
  ...>      output_type: 1
  ...>    }
  ...>  ],
  ...>  sigs: [],
  ...>  tx_data: <<0>>,
  ...>  tx_type: 1
  ...>}
  iex> :ok = ExPlasma.Transaction.validate(txn)
  """
  def validate(transaction) do
    with :ok <- Signed.validate(transaction),
         {:ok, module} <- get_transaction_module(transaction.tx_type) do
      module.validate(transaction)
    else
      {:error, :unrecognized_transaction_type} ->
        {:error, {:tx_type, :unrecognized_transaction_type}}

      {:error, {_field_atom, _error_atom}} = error ->
        error
    end
  end

  @doc """
  Returns the hash of the raw transaction involved without the signatures
  """
  @spec hash(t()) :: tx_hash()
  def hash(%__MODULE__{} = transaction), do: transaction |> encode() |> hash()
  def hash(tx_bytes) when is_binary(tx_bytes), do: Crypto.keccak_hash(tx_bytes)

  @doc """
  Signs the inputs of the transaction with the given keys in the corresponding order.
  Only signs transactions that implement the ExPlasma.TypedData protocol.

  Returns
  - {:ok, %Transaction{}} with sigs when succesfuly signed
  or
  - {:error, :not_signable} when the given transaction is not supported.

  ## Example

  iex> key = "0x79298b0292bbfa9b15705c56b6133201c62b798f102d7d096d31d7637f9b2382"
  iex> txn = %ExPlasma.Transaction.Type.PaymentV1.new([], [])
  iex> ExPlasma.Transaction.sign(txn, [key])
  %ExPlasma.Transaction{
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
  def sign(transaction, keys) do
    case Signed.compute_signatures(transaction, keys) do
      {:ok, sigs} -> {:ok, Map.put(transaction, :sigs, sigs)}
      {:error, :not_signable} = error -> error
    end
  end

  defp parse_tx_type(tx_type_rlp) do
    with {:ok, tx_type} <- RlpDecoder.parse_uint256(tx_type_rlp),
         {:ok, module} <- get_transaction_module(tx_type) do
      {:ok, tx_type, module}
    else
      _ -> {:error, :unrecognized_transaction_type}
    end
  end

  defp get_transaction_module(tx_type) do
    case Map.get(@tx_types_modules, tx_type) do
      nil -> {:error, :unrecognized_transaction_type}
      module -> {:ok, module}
    end
  end
end
