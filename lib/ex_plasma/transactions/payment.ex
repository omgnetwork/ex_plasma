defmodule ExPlasma.Transactions.Payment do
  @moduledoc """
  A Payment Transaction type. Used to send transactions from one party to another
  on the child chain

  * inputs - the list of inputs for this transaction
  * outputs - the list of outputs for this transaction
  * metadata - additional context.
  """

  alias __MODULE__

  @contract_input_count 4
  @contract_output_count 4

  @empty_input %{blknum: 0, txindex: 0, oindex: 0}
  @empty_output %{owner: 0, currency: 0, amount: 0}
  @empty_address <<0::160>>
  @empty_sig <<0::size(520)>>

  defstruct(
    inputs: [],
    outputs: [],
    metadata: <<0::160>>
  )

  @type t :: %__MODULE__{
          inputs: list(),
          outputs: list(map),
          metadata: binary()
        }

  @type input_t :: %{
          blknum: non_neg_integer,
          txindex: non_neg_integer,
          oindex: non_neg_integer
        }

  @type output_t :: %{
          owner: non_neg_integer,
          currency: non_neg_integer,
          amount: non_neg_integer
        }

  @doc """
  Creates a new `Transaction` struct, filling the inputs and outputs
  to the default sizes (see @contract_input_count and @contract_output_count).

  ## Examples

      Build a new empty Transaction
      iex(1)> ExPlasma.Transactions.Payment.new()
      %ExPlasma.Transactions.Payment{
        inputs: [
          %{blknum: 0, oindex: 0, txindex: 0},
          %{blknum: 0, oindex: 0, txindex: 0},
          %{blknum: 0, oindex: 0, txindex: 0},
          %{blknum: 0, oindex: 0, txindex: 0}
        ],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [
          %{amount: 0, currency: 0, owner: 0},
          %{amount: 0, currency: 0, owner: 0},
          %{amount: 0, currency: 0, owner: 0},
          %{amount: 0, currency: 0, owner: 0}
        ]
      }

      Build a new Transaction with inputs, outputs, and metadata
      iex(2)> ExPlasma.Transactions.Payment.new(%{inputs: [%{blknum: 1, txindex: 2, oindex: 3}], outputs: [%{owner: 1, currency: 1, amount: 1}], metadata: "foo"})
      %ExPlasma.Transactions.Payment{
        inputs: [
          %{blknum: 1, oindex: 3, txindex: 2},
          %{blknum: 0, oindex: 0, txindex: 0},
          %{blknum: 0, oindex: 0, txindex: 0},
          %{blknum: 0, oindex: 0, txindex: 0}
        ],
        metadata: "foo",
        outputs: [
          %{amount: 1, currency: 1, owner: 1},
          %{amount: 0, currency: 0, owner: 0},
          %{amount: 0, currency: 0, owner: 0},
          %{amount: 0, currency: 0, owner: 0}
        ]
      }
  """
  @spec new(map) :: t
  def new(), do: new(%{inputs: [], outputs: []})

  def new(%{inputs: inputs, outputs: outputs} = txn)
      when is_list(inputs) and length(inputs) <= @contract_input_count
      when is_list(outputs) and length(outputs) <= @contract_output_count do
    filled_inputs = inputs ++ List.duplicate(@empty_input, @contract_input_count - length(inputs))

    filled_outputs =
      outputs ++ List.duplicate(@empty_output, @contract_output_count - length(outputs))

    filled_txn = Map.merge(txn, %{inputs: filled_inputs, outputs: filled_outputs})

    struct(__MODULE__, filled_txn)
  end

  @doc """
  Transforms the `Transaction` into a list, especially for encoding.

  ## Examples

      Transforms a Transaction into an RLP consumable list.
      iex(1)> transaction = ExPlasma.Transactions.Payment.new
      iex(2)> ExPlasma.Transactions.Payment.to_list(transaction)
      [
        [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]],
        [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]],
        []
      ]
  """
  @spec to_list(t) :: list(any)
  def to_list(%__MODULE__{inputs: inputs, outputs: outputs, metadata: metadata}) do
    input_list = Enum.map(inputs, fn input -> Map.values(input) end)
    output_list = Enum.map(outputs, fn output -> Map.values(output) end)

    [input_list, output_list, metadata]
  end

  @doc """
  Encodes a `Transaction` into RLP encoding

  ## Examples

    iex(1)> t = ExPlasma.Transactions.Payment.new
    iex(2)> ExPlasma.Transactions.Payment.encode(t)
    <<227, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128, 128, 195,
      128, 128, 128, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128,
      128, 195, 128, 128, 128, 192>>
  """
  @spec encode(__MODULE__.t()) :: binary
  def encode(%__MODULE__{} = transaction), do: ExRLP.encode(transaction)

  @doc """
  Decodes a RLP encoding and transforms it back into a `Transaction`.

  ## Examples

      iex(1)> t = ExPlasma.Transactions.Payment.new
      iex(2)> e = ExPlasma.Transactions.Payment.encode(t)
      iex(3)> ExPlasma.Transactions.Payment.decode(e)
      %ExPlasma.Transactions.Payment{
        inputs: [
          %{blknum: 0, oindex: 0, txindex: 0},
          %{blknum: 0, oindex: 0, txindex: 0},
          %{blknum: 0, oindex: 0, txindex: 0},
          %{blknum: 0, oindex: 0, txindex: 0}
        ],
        metadata: 0,
        outputs: [
          %{amount: 0, currency: 0, owner: 0},
          %{amount: 0, currency: 0, owner: 0},
          %{amount: 0, currency: 0, owner: 0},
          %{amount: 0, currency: 0, owner: 0}
        ]
      }
  """
  @spec decode(binary) :: __MODULE__.t()
  def decode(encoding) when is_list(encoding) == false, do: decode(ExRLP.decode(encoding))

  def decode([inputs, outputs, metadata]) do
    decoded_inputs =
      Enum.map(inputs, fn [blknum, txindex, oindex] ->
        %{
          blknum: :binary.decode_unsigned(blknum, :big),
          txindex: :binary.decode_unsigned(txindex, :big),
          oindex: :binary.decode_unsigned(oindex, :big)
        }
      end)

    decoded_outputs =
      Enum.map(outputs, fn [owner, currency, amount] ->
        %{
          owner: :binary.decode_unsigned(owner, :big),
          currency: :binary.decode_unsigned(currency, :big),
          amount: :binary.decode_unsigned(amount, :big)
        }
      end)

    struct(__MODULE__, %{
      inputs: decoded_inputs,
      outputs: decoded_outputs,
      metadata: metadata
    })
  end

  @doc """
  Validates a transaction.

  ## Example

      iex(1)> t = ExPlasma.Transactions.Payment.new
      iex(2)> ExPlasma.Transactions.Payment.valid?(t)
      false
  """
  @spec valid?(t) :: boolean
  def valid?(%__MODULE__{} = transaction) do
    # TODO:
    # This should probably pass back tuples with why it's not valid.
    !duplicate_inputs?(transaction)
  end

  @doc """
  Checks to see if a transaction has duplicate inputs.

  ## Examples

      iex(1)> t = ExPlasma.Transactions.Payment.new
      iex(2)> ExPlasma.Transactions.Payment.duplicate_inputs?(t)
      true
  """
  @spec duplicate_inputs?(t) :: boolean
  defp duplicate_inputs?(%__MODULE__{inputs: inputs}) do
    inputs
    |> Enum.uniq()
    |> length() != length(inputs)
  end
end

defimpl ExRLP.Encode, for: ExPlasma.Transactions.Payment do
  alias ExRLP.Encode
  alias ExPlasma.Transactions.Payment

  @doc """
  Encodes a `Transaction` into RLP

  ## Examples

      Encodes a transaction
      iex(1)> transaction = ExPlasma.Transactions.Payment.new()
      iex(2)> ExRLP.encode(transaction)
      <<227, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128, 128, 195,
        128, 128, 128, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128,
        128, 195, 128, 128, 128, 192>>
  """
  @spec encode(Payment.t(), keyword) :: binary
  def encode(transaction, options \\ []) do
    transaction
    |> Payment.to_list()
    |> Encode.encode(options)
  end
end
