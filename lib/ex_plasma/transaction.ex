defmodule ExPlasma.Transaction do
  @moduledoc false

  alias ExPlasma.Output

  @type sigs() :: list(binary()) | []
  @type outputs() :: list(Output.t()) | []
  @type metadata :: <<_::160>> | nil

  @type t() :: %{
          sigs: sigs(),
          tx_type: pos_integer(),
          inputs: outputs(),
          outputs: outputs(),
          tx_data: any(),
          metadata: metadata()
        }

  @callback to_map(any()) :: map()
  @callback to_rlp(map()) :: any()
  @callback validate(any()) :: {:ok, map()} | {:error, {atom(), atom()}}

  @transaction_types %{
    1 => ExPlasma.Transaction.Type.PaymentV1
  }

  defstruct sigs: [], tx_type: 0, inputs: [], outputs: [], tx_data: 0, metadata: <<0::256>>

  @doc """
  Encode the given Transaction into an RLP encodeable list.

  ## Example

    iex> txn =
    ...>  %{
    ...>    inputs: [
    ...>      %{
    ...>        output_data: nil,
    ...>        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
    ...>        output_type: nil
    ...>      }
    ...>    ],
    ...>    metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    ...>    outputs: [
    ...>      %{
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
  def encode(%{} = transaction), do: transaction |> to_rlp() |> ExRLP.encode()
  def encode(transaction) when is_list(transaction), do: ExRLP.encode(transaction)

  @doc """
  Decode the given RLP list into a Transaction.

  ## Example

  iex> rlp = <<248, 74, 192, 1, 193, 128, 239, 174, 237, 1, 235, 148, 29, 246, 47, 41, 27,
  ...>   46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46,
  ...>   38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
  ...>   0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...>   0>>
  iex> ExPlasma.Transaction.decode(rlp)
  %{
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
  @spec decode(binary()) :: t()
  def decode(data), do: data |> ExRLP.decode() |> do_decode()

  defp do_decode([_tx_type, _inputs, _outputs, _tx_data, _metadata] = rlp),
    do: do_decode([[] | rlp])

  defp do_decode([_sigs, <<tx_type>>, _inputs, _outputs, _tx_data, _metadata] = rlp),
    do: @transaction_types[tx_type].to_map(rlp)

  @doc """
  Encode the given Transaction into an RLP encodeable list.

  ## Example

  iex> txn =
  ...>  %{
  ...>    inputs: [
  ...>      %{
  ...>        output_data: nil,
  ...>        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
  ...>        output_type: nil
  ...>      }
  ...>    ],
  ...>    metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
  ...>    outputs: [
  ...>      %{
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
  iex> ExPlasma.Transaction.to_rlp(txn)
  [
    <<1>>,
    [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>],
    [
      [
        <<1>>,
        [
          <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
          <<1>>
        ]
      ]
    ],
    0,
    <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  ]
  """
  def to_rlp(%{tx_type: tx_type} = transaction),
    do: transaction |> @transaction_types[tx_type].to_rlp() |> remove_empty_sigs()

  # NB: We need to standardize on this. Currently, if there is no sig, we strip the empty list.
  defp remove_empty_sigs([[] | raw_transaction_rlp]), do: raw_transaction_rlp

  @doc """
  Validate a Transation. This will check the inputs, outputs, and run
  the validation through the matching transaction type.


  ## Example

  iex> txn = %{inputs: [%{output_data: nil, output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}], metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, outputs: [%{output_data: %{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1}], sigs: [], tx_data: <<0>>, tx_type: 1}
  iex> {:ok, ^txn} = ExPlasma.Transaction.validate(txn)
  """
  def validate(%{} = transaction) do
    with {:ok, _inputs} <- validate_output(transaction.inputs),
         {:ok, _outputs} <- validate_output(transaction.outputs),
         {:ok, _transaaction} <- do_validate(transaction) do
      {:ok, transaction}
    end
  end

  defp validate_output([output | rest]) do
    with {:ok, _whatever} <- ExPlasma.Output.validate(output), do: validate_output(rest)
  end

  defp validate_output([]), do: {:ok, []}

  defp do_validate(%{tx_type: type} = transaction),
    do: @transaction_types[type].validate(transaction)

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
    sigs = Enum.map(keys, fn key -> ExPlasma.Encoding.signature_digest(eip712_hash, key) end)
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
  @spec hash(t() | binary()) :: <<_::256>>
  def hash(txn) when is_map(txn), do: txn |> encode() |> hash()
  def hash(txn) when is_binary(txn), do: ExPlasma.Encoding.keccak_hash(txn)
end
