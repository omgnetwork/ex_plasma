defmodule ExPlasma.Transaction.Type.PaymentV1.Validator do
  @moduledoc """
  Contain stateless validation logic for Payment V1 transactions
  """

  alias ExPlasma.Output
  alias ExPlasma.Transaction.TypeMapper

  @empty_tx_data 0
  @output_limit 4

  @output_type TypeMapper.output_type_for(:output_payment_v1)

  @type inputs_validation_error() :: {:inputs, :duplicate_inputs} | {:inputs, :cannot_exceed_maximum_value}

  @type outputs_validation_error() ::
          {:outputs, :cannot_exceed_maximum_value}
          | {:outputs, :cannot_subceed_minimum_value}
          | {:outputs, :invalid_output_type_for_transaction}

  defmacro is_metadata(metadata) do
    quote do
      is_binary(unquote(metadata)) and byte_size(unquote(metadata)) == 32
    end
  end

  @spec validate_inputs(list(Output)) :: :ok | {:error, inputs_validation_error()}
  def validate_inputs(inputs) do
    with :ok <- validate_generic_output(inputs),
         :ok <- validate_unique_inputs(inputs),
         :ok <- validate_outputs_count(:inputs, inputs, 0) do
      :ok
    end
  end

  @spec validate_outputs(list(Output)) :: :ok | {:error, outputs_validation_error()}
  def validate_outputs(outputs) do
    with :ok <- validate_generic_output(outputs),
         :ok <- validate_outputs_count(:outputs, outputs, 1),
         :ok <- validate_outputs_type(outputs) do
      :ok
    end
  end

  @spec validate_tx_data(any()) :: :ok | {:error, {:tx_data, :malformed_tx_data}}
  # txData is required to be zero in the contract
  def validate_tx_data(@empty_tx_data), do: :ok
  def validate_tx_data(_), do: {:error, {:tx_data, :malformed_tx_data}}

  @spec validate_metadata(<<_::256>>) :: :ok | {:error, {:metadata, :malformed_metadata}}
  def validate_metadata(metadata) when is_metadata(metadata), do: :ok
  def validate_metadata(_), do: {:error, {:metadata, :malformed_metadata}}

  defp validate_generic_output([output | rest]) do
    case Output.validate(output) do
      :ok -> validate_generic_output(rest)
      error -> error
    end
  end

  defp validate_generic_output([]), do: :ok

  defp validate_unique_inputs(inputs) do
    case inputs == Enum.uniq(inputs) do
      true -> :ok
      false -> {:error, {:inputs, :duplicate_inputs}}
    end
  end

  defp validate_outputs_count(field, list, _min_limit) when length(list) > @output_limit do
    {:error, {field, :cannot_exceed_maximum_value}}
  end

  defp validate_outputs_count(field, list, min_limit) when length(list) < min_limit do
    {:error, {field, :cannot_subceed_minimum_value}}
  end

  defp validate_outputs_count(_field, _list, _min_limit), do: :ok

  defp validate_outputs_type(outputs) do
    case Enum.all?(outputs, &(&1.output_type == @output_type)) do
      true -> :ok
      false -> {:error, {:outputs, :invalid_output_type_for_transaction}}
    end
  end
end
