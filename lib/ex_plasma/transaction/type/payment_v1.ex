defmodule ExPlasma.Transaction.Type.PaymentV1 do
  @moduledoc """
  Internal representation of a raw payment transaction done on Plasma chain.

  This module holds the representation of a "raw" transaction, i.e. without signatures nor recovered input spenders
  """
  require __MODULE__.Validator

  alias ExPlasma.Crypto
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.TypeMapper
  alias __MODULE__.Validator
  alias ExPlasma.Output
  alias ExPlasma.Utils.RlpDecoder

  @empty_metadata <<0::256>>
  @empty_tx_data 0

  @tx_type TypeMapper.tx_type_for(:tx_payment_v1)
  @output_type TypeMapper.output_type_for(:output_payment_v1)

  @type outputs() :: list(Output.t()) | []
  @type metadata() :: <<_::256>> | nil

  @type validation_error() ::
          Validator.inputs_validation_error()
          | Validator.outputs_validation_error()
          | {:tx_data, :malformed_tx_data}
          | {:metadata, :malformed_metadata}

  @type mapping_error() ::
          :malformed_transaction
          | :malformed_tx_data
          | :malformed_inputs
          | :malformed_outputs

  @behaviour ExPlasma.Transaction

  @doc """
  Creates output for a payment v1 transaction

  ## Example

  iex> output = new_output(<<1::160>>, <<0::160>>, 1)
  iex> %ExPlasma.Output{
  ...>   output_data: %{amount: 1, output_guard: <<1::160>>, token: <<0::160>>},
  ...>   output_id: nil,
  ...>   output_type: 1
  ...> } = output
  """
  @spec new_output(Crypto.address_t(), Crypto.address_t(), pos_integer()) :: Output.t()
  def new_output(owner, token, amount) do
    %Output{
      output_type: @output_type,
      output_data: %{
        amount: amount,
        output_guard: owner,
        token: token
      }
    }
  end

  @doc """
  Turns a structure instance into a structure of RLP items, ready to be RLP encoded, for a raw transaction
  """
  @spec to_rlp(Transaction.t()) :: list()
  @impl Transaction
  def to_rlp(transaction) do
    [
      <<@tx_type>>,
      Enum.map(transaction.inputs, &Output.to_rlp_id/1),
      Enum.map(transaction.outputs, &Output.to_rlp/1),
      @empty_tx_data,
      transaction.metadata || @empty_metadata
    ]
  end

  @doc """
  Decodes an RLP list into a Payment V1 Transaction.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec to_map(list()) :: {:ok, Transaction.t()} | {:error, mapping_error()}
  @impl Transaction
  def to_map([<<@tx_type>>, inputs_rlp, outputs_rlp, tx_data_rlp, metadata_rlp]) do
    with {:ok, inputs} <- decode_inputs(inputs_rlp),
         {:ok, outputs} <- decode_outputs(outputs_rlp),
         {:ok, tx_data} <- decode_tx_data(tx_data_rlp),
         {:ok, metadata} <- decode_metadata(metadata_rlp) do
      {:ok,
       %Transaction{
         tx_type: @tx_type,
         inputs: inputs,
         outputs: outputs,
         tx_data: tx_data,
         metadata: metadata
       }}
    end
  end

  def to_map(_, _), do: {:error, :malformed_transaction}

  @doc """
  Validates the Transaction.
  """
  @spec validate(Transaction.t()) :: :ok | {:error, validation_error()}
  @impl Transaction
  def validate(transaction) do
    with :ok <- Validator.validate_inputs(transaction.inputs),
         :ok <- Validator.validate_outputs(transaction.outputs),
         :ok <- Validator.validate_tx_data(transaction.tx_data),
         :ok <- Validator.validate_metadata(transaction.metadata) do
      :ok
    end
  end

  defp decode_inputs(inputs_rlp) do
    {:ok, Enum.map(inputs_rlp, &Output.decode_id(&1))}
  rescue
    _ -> {:error, :malformed_inputs}
  end

  defp decode_outputs(outputs_rlp) do
    {:ok, Enum.map(outputs_rlp, &Output.decode(&1))}
  rescue
    _ -> {:error, :malformed_outputs}
  end

  defp decode_metadata(metadata_rlp) when Validator.is_metadata(metadata_rlp), do: {:ok, metadata_rlp}
  defp decode_metadata(_), do: {:error, :malformed_metadata}

  defp decode_tx_data(@empty_tx_data), do: {:ok, @empty_tx_data}

  defp decode_tx_data(tx_data_rlp) do
    case RlpDecoder.parse_uint256(tx_data_rlp) do
      {:ok, tx_data} -> {:ok, tx_data}
      _ -> {:error, :malformed_tx_data}
    end
  end
end
