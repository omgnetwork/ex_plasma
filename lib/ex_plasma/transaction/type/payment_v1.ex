defmodule ExPlasma.Transaction.Type.PaymentV1 do
  @moduledoc """
  Implementation of Transaction behaviour for Payment V1 type.
  """

  @behaviour ExPlasma.Transaction

  alias __MODULE__.Validator
  alias ExPlasma.Crypto
  alias ExPlasma.Output
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.TypeMapper
  alias ExPlasma.Utils.RlpDecoder

  require __MODULE__.Validator

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
          | :malformed_input_position_rlp
          | :malformed_output_rlp

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

  @impl Transaction
  def build_nonce(_params), do: {:ok, nil}

  @doc """
  Turns a structure instance into a structure of RLP items, ready to be RLP encoded
  """
  @impl Transaction
  def to_rlp(transaction) do
    with {:ok, inputs} <- encode_inputs(transaction.inputs),
         {:ok, outputs} <- encode_outputs(transaction.outputs) do
      {:ok,
       [
         <<@tx_type>>,
         inputs,
         outputs,
         @empty_tx_data,
         transaction.metadata || @empty_metadata
       ]}
    end
  end

  @doc """
  Decodes an RLP list into a Payment V1 Transaction.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @impl Transaction
  def to_map([<<@tx_type>>, inputs_rlp, outputs_rlp, tx_data_rlp, metadata_rlp]) do
    with {:ok, inputs} <- map_inputs(inputs_rlp),
         {:ok, outputs} <- map_outputs(outputs_rlp),
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

  def to_map(_), do: {:error, :malformed_transaction}

  @doc """
  Validates the Transaction.
  """
  @impl Transaction
  def validate(transaction) do
    with :ok <- Validator.validate_inputs(transaction.inputs),
         :ok <- Validator.validate_outputs(transaction.outputs),
         :ok <- Validator.validate_tx_data(transaction.tx_data),
         :ok <- Validator.validate_metadata(transaction.metadata) do
      :ok
    end
  end

  defp encode_inputs(inputs) when is_list(inputs), do: reduce_outputs(inputs, [], &Output.to_rlp_id/1)
  defp encode_inputs(_inputs), do: {:error, :malformed_input_position_rlp}

  defp encode_outputs(outputs) when is_list(outputs), do: reduce_outputs(outputs, [], &Output.to_rlp/1)
  defp encode_outputs(_outputs), do: {:error, :malformed_output_rlp}

  defp map_inputs(inputs) when is_list(inputs), do: reduce_outputs(inputs, [], &Output.decode_id/1)
  defp map_inputs(_inputs), do: {:error, :malformed_input_position_rlp}

  defp map_outputs(outputs) when is_list(outputs), do: reduce_outputs(outputs, [], &Output.to_map/1)
  defp map_outputs(_outputs), do: {:error, :malformed_output_rlp}

  defp reduce_outputs([], reduced, _reducing_func), do: {:ok, Enum.reverse(reduced)}

  defp reduce_outputs([output | rest], reduced, reducing_func) do
    case reducing_func.(output) do
      {:ok, item} -> reduce_outputs(rest, [item | reduced], reducing_func)
      error -> error
    end
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
