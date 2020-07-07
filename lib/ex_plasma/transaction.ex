defmodule ExPlasma.Transaction do
  @moduledoc false

  alias ExPlasma.Transaction.Type.Fee
  alias ExPlasma.Transaction.Type.PaymentV1

  @callback to_map(any()) :: map()
  @callback to_rlp(map()) :: any()
  @callback validate(any()) :: {:ok, map()} | {:error, {atom(), atom()}}

  @transaction_types %{
    1 => PaymentV1,
    3 => Fee
  }

  @type transaction_types :: PaymentV1.t() | Fee.t()

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
  @spec encode(transaction_types() | list(binary())) :: binary()
  def encode(transactions) when is_list(transactions), do: ExRLP.encode(transactions)

  def encode(%module{} = transaction) when is_map(transaction) do
    transaction |> module.to_rlp() |> ExRLP.encode()
  end

  @doc """
  Decode the given RLP list into a Transaction.

  ## Example

  iex> rlp = <<248, 74, 192, 1, 193, 128, 239, 174, 237, 1, 235, 148, 29, 246, 47, 41, 27,
  ...>   46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46,
  ...>   38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
  ...>   0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...>   0>>
  iex> ExPlasma.Transaction.decode(1, rlp)
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
  @spec decode(pos_integer() | atom(), binary()) :: transaction_types() | no_return()
  def decode(tx_type_or_module, data), do: data |> ExRLP.decode() |> do_decode(tx_type_or_module)

  defp do_decode(rlp, tx_type) when is_integer(tx_type) do
    module = get_transaction_type(tx_type)
    do_decode(rlp, module)
  end

  defp do_decode(rlp, tx_module), do: tx_module.to_map(rlp)

  @doc """

  """
  @spec new(pos_integer() | atom(), keyword()) :: transaction_types() | no_return()
  def new(tx_type, opts) when is_integer(tx_type) do
    tx_type |> get_transaction_type() |> new(opts)
  end

  def new(module, opts) do
    struct(module, opts)
  end

  def recover_signatures(transaction) do
    hash = ExPlasma.TypedData.hash(transaction)

    transaction.sigs
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, []}, fn signature, {:ok, addresses} ->
      case ExPlasma.Crypto.recover_address(hash, signature) do
        {:ok, address} ->
          {:cont, {:ok, [address | addresses]}}

        error ->
          {:halt, error}
      end
    end)
  end

  @spec validate(transaction_types()) :: tuple()
  def validate(%module{} = transaction) do
    module.validate(transaction)
  end

  @doc """
  Sign the inputs of the transaction with the given keys in the corresponding order.


  ## Example

    iex> key = "0x79298b0292bbfa9b15705c56b6133201c62b798f102d7d096d31d7637f9b2382"
    iex> txn = %ExPlasma.Transaction{tx_type: 1}
    iex> ExPlasma.Transaction.sign(txn, keys: [key])
    %ExPlasma.Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [
              <<129, 213, 32, 15, 183, 218, 255, 22, 82, 95, 22, 86, 103, 227, 92, 109, 9,
                89, 7, 142, 235, 107, 203, 29, 20, 231, 91, 168, 255, 119, 204, 239, 44,
                125, 76, 109, 200, 196, 204, 230, 224, 241, 84, 75, 9, 3, 160, 177, 37,
                181, 174, 98, 51, 15, 136, 235, 47, 96, 15, 209, 45, 85, 153, 2, 28>>
            ],
        tx_data: 0,
        tx_type: 1
    }
  """
  def sign(%{} = transaction, keys: []), do: %{transaction | sigs: []}

  def sign(%{} = transaction, keys: keys) when is_list(keys) do
    eip712_hash = ExPlasma.TypedData.hash(transaction)
    sigs = Enum.map(keys, fn key -> ExPlasma.Signature.signature_digest(eip712_hash, key) end)
    %{transaction | sigs: sigs}
  end

  @doc """
  Keccak hash the Transaction. This is used in the contracts and events to to reference transactions.


  ## Example

  iex> rlp = <<248, 74, 192, 1, 193, 128, 239, 174, 237, 1, 235, 148, 29, 246, 47, 41, 27,
  ...> 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46,
  ...> 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
  ...> 0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...> 0>>
  iex> ExPlasma.Transaction.hash(rlp)
  <<87, 132, 239, 36, 144, 239, 129, 88, 63, 88, 116, 147, 164, 200, 113, 191,
    124, 14, 55, 131, 119, 96, 112, 13, 28, 178, 251, 49, 16, 127, 58, 96>>
  """
  @spec hash(transaction_types() | binary()) :: <<_::256>>
  def hash(txn) when is_map(txn), do: txn |> encode() |> hash()
  def hash(txn) when is_binary(txn), do: ExPlasma.Encoding.keccak_hash(txn)

  defp get_transaction_type(type) do
    case Map.fetch(@transaction_types, type) do
      {:ok, type} ->
        type

      :error ->
        raise ArgumentError, "transaction type #{type} does not exist."
    end
  end
end
