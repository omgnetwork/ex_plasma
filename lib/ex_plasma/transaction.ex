defmodule ExPlasma.Transaction do
  @moduledoc """
  The base transaction for now. There's actually a lot of different
  transaction types.
  """

  alias __MODULE__
  alias ExPlasma.Utxo

  # This is the base Transaction. It's not meant to be used, so these
  # are 0 value for now so that we can test these functions.
  @transaction_type 0
  @output_type 0

  @empty_transaction_data 0
  @empty_metadata <<0::256>>

  # The RLP encoded transaction as a binary
  @type tx_bytes :: <<_::632>>
  # Binary representation of an address
  @type address :: <<_::160>>
  # Hash string representation of an address
  @type address_hash :: <<_::336>>
  # Metadata field. Currently unusued.
  @type metadata :: <<_::160>>

  @type t :: %__MODULE__{
          sigs: [binary()] | [],
          inputs: [ExPlasma.Utxo.t()] | [],
          outputs: [ExPlasma.Utxo.t()] | [],
          metadata: __MODULE__.metadata() | nil
        }

  @callback new(map()) :: struct()
  @callback transaction_type() :: non_neg_integer()
  @callback output_type() :: non_neg_integer()

  # @callback decode(binary) :: struct()

  defstruct(tx_type: nil, sigs: [], inputs: [], outputs: [], tx_data: nil, metadata: nil)

  @doc """
  The associated value for the output type.  This is the base representation
  and is 0 because it does not exist.
  """
  @spec output_type() :: 0
  def output_type(), do: @output_type

  @doc """
  The transaction type value as defined by the contract. This is the base representation
  and is 0 because it does not exist.
  """
  @spec transaction_type() :: 0
  def transaction_type(), do: @transaction_type

  @doc """
  Generate a new Transaction. This generates an empty transaction
  as this is the base class.

  ## Examples

    iex> ExPlasma.Transaction.new(%ExPlasma.Transaction{inputs: [], outputs: []})
    %ExPlasma.Transaction{
      inputs: [],
      outputs: [],
      tx_data: nil,
      tx_type: nil,
      metadata: nil
    }

    # Create a transaction from a RLP list
    iex> rlp = [
    ...>  <<1>>,
    ...>  [<<0>>],
    ...>  [
    ...>    [
    ...>      <<1>>,
    ...>      [
    ...>        <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65,
    ...>          226, 241, 55, 0, 110>>,
    ...>        <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
    ...>          241, 55, 0, 110>>,
    ...>        <<0, 0, 0, 0, 0, 0, 0, 1>>
    ...>      ]
    ...>    ]
    ...>  ],
    ...>  <<0>>,
    ...>  <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    ...>]
    iex> ExPlasma.Transaction.new(rlp)
  	 %ExPlasma.Transaction{inputs: [%ExPlasma.Utxo{amount: nil, blknum: 0, currency: nil, oindex: 0, owner: nil, txindex: 0 }],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [%ExPlasma.Utxo{amount: 1, blknum: nil, currency: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, oindex: nil, owner: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, txindex: nil}],
        tx_data: 0,
        tx_type: 1,
        sigs: []}
  """
  @spec new(struct() | nonempty_maybe_improper_list()) :: struct() | {:error, {atom(), atom()}}
  def new(%module{inputs: inputs, outputs: outputs} = transaction)
      when is_list(inputs) and is_list(outputs) do
    struct(module, Map.from_struct(transaction))
  end

  def new([tx_type, inputs, outputs, <<tx_data>>, metadata]),
    do: new([tx_type, inputs, outputs, tx_data, metadata])

  def new([<<tx_type>>, inputs, outputs, tx_data, metadata]),
    do: new([tx_type, inputs, outputs, tx_data, metadata])

  def new([tx_type, inputs, outputs, tx_data, metadata]),
    do: new([[], tx_type, inputs, outputs, tx_data, metadata])

  def new([sigs, tx_type, inputs, outputs, tx_data, metadata]) do
    with {:ok, inputs} <- build_utxos(inputs),
         {:ok, outputs} <- build_utxos(outputs) do
      %__MODULE__{
        tx_type: tx_type,
        sigs: sigs,
        inputs: inputs,
        outputs: outputs,
        tx_data: tx_data,
        metadata: metadata
      }
    end
  end

  @doc """
  Generate an RLP-encodable list for the transaction.

  ## Examples

  iex> txn = %ExPlasma.Transaction{}
  iex> ExPlasma.Transaction.to_rlp(txn)
  [0, [], [], 0, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>]
  """
  @spec to_rlp(struct()) :: list()
  def to_rlp(%module{sigs: [], inputs: inputs, outputs: outputs, metadata: metadata})
      when is_list(inputs) and is_list(outputs) do
    computed_inputs = Enum.map(inputs, &Utxo.to_input_rlp/1)
    computed_outputs = Enum.map(outputs, &Utxo.to_output_rlp/1)

    metadata = metadata || @empty_metadata

    [
      module.transaction_type(),
      computed_inputs,
      computed_outputs,
      @empty_transaction_data,
      metadata
    ]
  end

  def to_rlp(%_module{sigs: sigs} = transaction) when is_list(sigs),
    do: [sigs | to_rlp(%{transaction | sigs: []})]

  @doc """
  Encodes a transaction into an RLP encodable list.

  ## Examples

  iex> txn = %ExPlasma.Transaction{}
  iex> ExPlasma.Transaction.encode(txn)
  <<229, 128, 192, 192, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  """
  @spec encode(map()) :: __MODULE__.tx_bytes()
  def encode(%{} = transaction), do: transaction |> Transaction.to_rlp() |> ExRLP.Encode.encode()

  @doc """
  Encodes a transaction into an RLP encodable list.

  ## Examples

    iex> rlp_encoded = <<248, 116, 128, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 237, 1, 235, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    iex> ExPlasma.Transaction.decode(rlp_encoded)
    %ExPlasma.Transaction{
      inputs: [
        %ExPlasma.Utxo{
          amount: nil,
          blknum: 0,
          currency: nil,
          oindex: 0,
          output_type: 1,
          owner: nil,
          txindex: 0
        }
      ],
      metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      outputs: [
        %ExPlasma.Utxo{
          amount: 1,
          blknum: nil,
          currency: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
          oindex: nil,
          output_type: 1,
          owner: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
          txindex: nil
        }
      ],
      tx_type: "",
      tx_data: "",
      sigs: []
    }

    # Create a transaction from a signed encoded hash of a transaction
    iex> signed_encoded_hash = "0xf85ef843b841aa061b1df64f0b5c3bd350d9444b8fd2d02d4523abb23fbe8d270d6bc2e782c037d45e0c0afaf615cfc0701f4cde6af04f60ddb756e52f8459f459f1e65dcd511b80c0c080940000000000000000000000000000000000000000"
    iex> signed_encoded_hash |> ExPlasma.Encoding.to_binary() |> ExPlasma.Transaction.decode()
    %ExPlasma.Transaction{
      tx_type: "",
      tx_data: "",
      inputs: [],
      metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      outputs: [],
      sigs: [
        <<170, 6, 27, 29, 246, 79, 11, 92, 59, 211, 80, 217, 68, 75, 143, 210, 208,
          45, 69, 35, 171, 178, 63, 190, 141, 39, 13, 107, 194, 231, 130, 192, 55,
          212, 94, 12, 10, 250, 246, 21, 207, 192, 112, 31, 76, 222, 106, 240, 79,
          96, 221, 183, 86, 229, 47, 132, 89, 244, 89, 241, 230, 93, 205, 81, 27>>
      ]
    }
  """
  def decode(rlp_encoded_txn), do: rlp_encoded_txn |> ExRLP.decode() |> Transaction.new()


  @doc """
  Keccak hash a transaction.

  ## Examples

      # Hash a transaction
      iex> txn = %ExPlasma.Transaction{}
      iex> ExPlasma.Transaction.hash(txn)
      <<95, 34, 177, 98, 209, 215, 55, 18, 40, 254, 215, 73, 183, 221,
        118, 253, 137, 66, 155, 62, 39, 96, 202, 110, 29, 216, 60, 225,
        201, 158, 136, 67>>

      # Hash an encoded transaction bytes
      iex> tx_bytes = ExPlasma.Transaction.encode(%ExPlasma.Transaction{})
      iex> ExPlasma.Transaction.hash(tx_bytes)
      <<95, 34, 177, 98, 209, 215, 55, 18, 40, 254, 215, 73, 183, 221,
        118, 253, 137, 66, 155, 62, 39, 96, 202, 110, 29, 216, 60, 225,
        201, 158, 136, 67>>
  """
  def hash(txn) when is_map(txn), do: txn |> encode() |> hash()
  def hash(txn) when is_binary(txn), do: ExPlasma.Encoding.keccak_hash(txn)

  @doc """

    ## Examples

      # Signs transaction with the given key.
      iex> txn = %ExPlasma.Transaction{metadata: <<0::160>>} 
      iex> key = "0x79298b0292bbfa9b15705c56b6133201c62b798f102d7d096d31d7637f9b2382"
      iex> ExPlasma.Transaction.sign(txn, keys: [key])
      %ExPlasma.Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [
          <<105, 151, 242, 23, 175, 7, 237, 244, 242, 110, 41, 1, 242, 106, 61, 65,
            85, 117, 213, 245, 188, 155, 84, 3, 131, 195, 107, 76, 179, 55, 195, 148,
            84, 167, 162, 147, 33, 147, 74, 24, 136, 15, 26, 202, 78, 80, 182, 183,
            206, 139, 75, 29, 91, 90, 136, 158, 223, 112, 82, 222, 37, 55, 104, 202,
            27>>
        ]
      }

      # Signs the transaction with no keys.
      iex> txn = %ExPlasma.Transaction{metadata: <<0::160>>} 
      iex> ExPlasma.Transaction.sign(txn, keys: [])
      %ExPlasma.Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: []
      }
  """
  @spec sign(__MODULE__.t(), keys: []) :: __MODULE__.t()
  def sign(%{} = transaction, keys: []), do: %{transaction | sigs: []}

  def sign(%{} = transaction, keys: keys) when is_list(keys) do
    eip712_hash = ExPlasma.TypedData.hash(transaction)
    sigs = Enum.map(keys, fn key -> ExPlasma.Encoding.signature_digest(eip712_hash, key) end)
    %{transaction | sigs: sigs}
  end

  # Builds list of utxos and propogates error tuples up the stack.
  defp build_utxos(utxos), do: build_utxos(utxos, [])
  defp build_utxos([], acc), do: {:ok, Enum.reverse(acc)}

  defp build_utxos([utxo | utxos], acc) do
    case Utxo.new(utxo) do
      {:ok, utxo} ->
        build_utxos(utxos, [utxo | acc])

      {:error, reason} ->
        {:error, reason}
    end
  end
end
