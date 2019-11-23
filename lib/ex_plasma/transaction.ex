defmodule ExPlasma.Transaction do
  @moduledoc """
  The base transaction for now. There's actually a lot of different
  transaction types.
  """

  alias __MODULE__
  alias __MODULE__.Utxo

  # This is the base Transaction. It's not meant to be used, so these
  # are 0 value for now so that we can test these functions.
  @transaction_type 0
  @output_type 0
  @empty_metadata <<0::160>>

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
  	 %ExPlasma.Transaction{inputs: [%ExPlasma.Transaction.Utxo{amount: 0, blknum: 0, currency: "0x0000000000000000000000000000000000000000", oindex: 0, owner: "0x0000000000000000000000000000000000000000", txindex: 0 }],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [%ExPlasma.Transaction.Utxo{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, blknum: 0, currency: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, oindex: 0, owner: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, txindex: 0}],
        sigs: []}
  """
  @spec new(struct()) :: struct()
  def new(%module{inputs: inputs, outputs: outputs} = transaction)
      when is_list(inputs) and is_list(outputs) do
    struct(module, Map.from_struct(transaction))
  end

  def new([_transaction_type, inputs, outputs, metadata]) do
    %__MODULE__{
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
  [<<0>>, [], [], <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>]
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
  <<216, 0, 192, 192, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  """
  @spec encode(map()) :: __MODULE__.tx_bytes()
  def encode(%{} = transaction), do: transaction |> Transaction.to_list() |> ExRLP.Encode.encode()

  @doc """
  Encodes a transaction into an RLP encodable list.

  ## Examples

    iex> rlp_encoded = <<248, 78, 1, 193, 0, 245, 244, 1, 148, 29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 136, 0, 0, 0, 0, 0, 0, 0, 1, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    iex> ExPlasma.Transaction.decode(rlp_encoded)
    %ExPlasma.Transaction{inputs: [%ExPlasma.Transaction.Utxo{amount: 0, blknum: 0, currency: "0x0000000000000000000000000000000000000000", oindex: 0, owner: "0x0000000000000000000000000000000000000000", txindex: 0 }],
     metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
     outputs: [%ExPlasma.Transaction.Utxo{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, blknum: 0, currency: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, oindex: 0, owner: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, txindex: 0}],
     sigs: []}
  """
  def decode(rlp_encoded_txn), do: rlp_encoded_txn |> ExRLP.decode() |> Transaction.new()
end

defimpl ExPlasma.TypedData, for: [
  ExPlasma.Transaction,
  ExPlasma.Transactions.Deposit,
  ExPlasma.Transactions.Payment] do

    @signature "Transaction(uint256 txType,Input input0,Input input1,Input input2,Input input3,Output output0,Output output1,Output output2,Output output3,bytes32 metadata)"

    def encode(%module{inputs: inputs, outputs: outputs, metadata: metadata}) do
      encoded_inputs = Enum.map(inputs, &ExPlasma.TypedData.encode_input/1)
      encoded_outputs = Enum.map(outputs, &ExPlasma.TypedData.encode_output/1)
      transaction_type = :binary.decode_unsigned(module.transaction_type())
      encoded_transaction_type = ABI.TypeEncoder.encode_raw([transaction_type], [{:uint, 256}])

      [
        @signature,
        encoded_transaction_type,
        encoded_inputs,
        encoded_outputs,
        metadata
      ]
    end
end
