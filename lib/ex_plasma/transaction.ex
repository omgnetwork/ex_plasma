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
          inputs: [Utxo.t()] | [],
          outputs: [Utxo.t()] | [],
          metadata: __MODULE__.metadata() | nil
        }

  @callback new(map()) :: struct()
  @callback transaction_type() :: non_neg_integer()
  @callback output_type() :: non_neg_integer()

  # @callback decode(binary) :: struct()

  defstruct(sigs: [], inputs: [], outputs: [], metadata: nil)

  @doc """
  The associated value for the output type.  This is the base representation
  and is 0 because it does not exist.
  """
  @spec output_type() :: non_neg_integer()
  def output_type(), do: @output_type

  @doc """
  The transaction type value as defined by the contract. This is the base representation
  and is 0 because it does not exist.
  """
  @spec transaction_type() :: non_neg_integer()
  def transaction_type(), do: @transaction_type

  @doc """
  Generate a new Transaction. This generates an empty transaction
  as this is the base class.

  ## Examples

    iex> ExPlasma.Transaction.new(%ExPlasma.Transaction{inputs: [], outputs: []})
    %ExPlasma.Transaction{
      inputs: [],
      outputs: [],
      metadata: nil
    }

    # Create a transaction from a RLP list
    iex> rlp = [
    ...>  <<1>>,
    ...>  [<<0>>],
    ...>  [
    ...>    [
    ...>      <<1>>,
    ...>      <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65,
    ...>        226, 241, 55, 0, 110>>,
    ...>      <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
    ...>        241, 55, 0, 110>>,
    ...>      <<0, 0, 0, 0, 0, 0, 0, 1>>
    ...>    ]
    ...>  ],
    ...>  <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    ...>]
    iex> ExPlasma.Transaction.new(rlp)
  	 %ExPlasma.Transaction{inputs: [%ExPlasma.Utxo{amount: 0, blknum: 0, currency: "0x0000000000000000000000000000000000000000", oindex: 0, owner: "0x0000000000000000000000000000000000000000", txindex: 0 }],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [%ExPlasma.Utxo{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, blknum: 0, currency: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, oindex: 0, owner: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, txindex: 0}],
        sigs: []}
  """
  @spec new(struct() | nonempty_maybe_improper_list()) :: struct()
  def new(%module{inputs: inputs, outputs: outputs} = transaction)
      when is_list(inputs) and is_list(outputs) do
    struct(module, Map.from_struct(transaction))
  end

  def new([transaction_type, inputs, outputs, metadata]),
    do: new([[], transaction_type, inputs, outputs, metadata])

  def new([sigs, _transaction_type, inputs, outputs, metadata]) do
    %__MODULE__{
      sigs: sigs,
      inputs: Enum.map(inputs, &Utxo.new/1),
      outputs: Enum.map(outputs, &Utxo.new/1),
      metadata: metadata
    }
  end

  @doc """
  Generate an RLP-encodable list for the transaction.

  ## Examples

  iex> txn = %ExPlasma.Transaction{}
  iex> ExPlasma.Transaction.to_list(txn)
  [<<0>>, [], [], <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>]
  """
  @spec to_list(struct()) :: list()
  def to_list(%module{sigs: [], inputs: inputs, outputs: outputs, metadata: metadata})
      when is_list(inputs) and is_list(outputs) do
    computed_inputs = Enum.map(inputs, &Utxo.to_input_list/1)
    computed_outputs = Enum.map(outputs, &Utxo.to_output_list/1)

    metadata = metadata || @empty_metadata

    [
      <<module.transaction_type()>>,
      computed_inputs,
      computed_outputs,
      metadata
    ]
  end

  def to_list(%_module{sigs: sigs} = transaction) when is_list(sigs),
    do: [sigs | to_list(%{transaction | sigs: []})]

  @doc """
  Encodes a transaction into an RLP encodable list.

  ## Examples

  iex> txn = %ExPlasma.Transaction{}
  iex> ExPlasma.Transaction.encode(txn)
  <<228, 0, 192, 192, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  """
  @spec encode(map()) :: __MODULE__.tx_bytes()
  def encode(%{} = transaction), do: transaction |> Transaction.to_list() |> ExRLP.Encode.encode()

  @doc """
  Encodes a transaction into an RLP encodable list.

  ## Examples

    iex> rlp_encoded = <<248, 78, 1, 193, 0, 245, 244, 1, 148, 29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 136, 0, 0, 0, 0, 0, 0, 0, 1, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    iex> ExPlasma.Transaction.decode(rlp_encoded)
    %ExPlasma.Transaction{inputs: [%ExPlasma.Utxo{amount: 0, blknum: 0, currency: "0x0000000000000000000000000000000000000000", oindex: 0, owner: "0x0000000000000000000000000000000000000000", txindex: 0 }],
     metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
     outputs: [%ExPlasma.Utxo{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, blknum: 0, currency: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, oindex: 0, owner: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, txindex: 0}],
     sigs: []}

    # Create a transaction from a signed encoded hash of a transaction
    iex> signed_encoded_hash = "0xf85df843b841c4841bfe271a5971dbebbf827f70bb16d84bcef67bcb83433a4d8d7d309091b8059ce54955434b3d449e1571d2122cab65a0bc69d324e692275862ff4e0e51761c00c0c0940000000000000000000000000000000000000000"
    iex> signed_encoded_hash |> ExPlasma.Encoding.to_binary() |> ExPlasma.Transaction.decode()
    %ExPlasma.Transaction{
      inputs: [],
      metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      outputs: [],
      sigs: [
        <<196, 132, 27, 254, 39, 26, 89, 113, 219, 235, 191, 130, 127, 112, 187, 22,
          216, 75, 206, 246, 123, 203, 131, 67, 58, 77, 141, 125, 48, 144, 145, 184,
          5, 156, 229, 73, 85, 67, 75, 61, 68, 158, 21, 113, 210, 18, 44, 171, 101,
          160, 188, 105, 211, 36, 230, 146, 39, 88, 98, 255, 78, 14, 81, 118, 28>>
      ]
    }

  """
  def decode(rlp_encoded_txn), do: rlp_encoded_txn |> ExRLP.decode() |> Transaction.new()

  @doc """

    ## Examples

      iex> txn = %ExPlasma.Transaction{metadata: <<0::160>>} 
      iex> key = "0x79298b0292bbfa9b15705c56b6133201c62b798f102d7d096d31d7637f9b2382"
      iex> ExPlasma.Transaction.sign(txn, keys: [key])
      %ExPlasma.Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [
          <<183, 180, 93, 111, 154, 78, 192, 155, 167, 148, 194, 222, 62, 159, 175,
            21, 163, 234, 195, 178, 55, 219, 197, 177, 202, 130, 65, 14, 62, 138, 230,
            180, 126, 66, 75, 96, 112, 91, 16, 54, 230, 143, 0, 188, 49, 241, 48, 6,
            146, 30, 247, 81, 220, 146, 35, 143, 242, 46, 193, 30, 60, 245, 198, 18,
            28>>
        ]
      }
  """
  def sign(%__MODULE__{} = transaction, keys: keys) when is_list(keys) do
    eip712_hash = ExPlasma.TypedData.hash(transaction)
    sigs = Enum.map(keys, fn key -> ExPlasma.Encoding.signature_digest(eip712_hash, key) end)
    %{transaction | sigs: sigs}
  end
end
