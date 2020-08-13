defmodule ExPlasma.Transaction.Type.Fee.Validator do
  @moduledoc """
  Contain stateless validation logic for Fee transactions
  """

  alias ExPlasma.Output
  alias ExPlasma.Transaction.TypeMapper

  @output_type TypeMapper.output_type_for(:output_fee_token_claim)

  @type outputs_validation_error() ::
          {:outputs, :wrong_number_of_fee_outputs}
          | {:outputs, :fee_output_amount_has_to_be_positive}
          | {:outputs, :invalid_output_type_for_transaction}

  @spec validate_outputs(list(Output)) :: :ok | {:error, outputs_validation_error()}
  def validate_outputs(outputs) do
    with {:ok, output} <- validate_outputs_count(outputs),
         :ok <- validate_generic_output(output),
         :ok <- validate_output_type(output),
         :ok <- validate_output_amount(output) do
      :ok
    end
  end

  defp validate_generic_output(output) do
    with {:ok, _} <- Output.validate(output), do: :ok
  end

  defp validate_outputs_count([output]), do: {:ok, output}
  defp validate_outputs_count(_outputs), do: {:error, {:outputs, :wrong_number_of_fee_outputs}}

  defp validate_output_type(%Output{output_type: @output_type}), do: :ok
  defp validate_output_type(_output), do: {:error, {:outputs, :invalid_output_type_for_transaction}}

  defp validate_output_amount(%Output{output_data: %{amount: amount}}) when amount > 0, do: :ok
  defp validate_output_amount(_output), do: {:error, {:outputs, :fee_output_amount_has_to_be_positive}}

  @spec validate_nonce(binary()) :: :ok | {:error, {:nonce, :malformed_nonce}}
  def validate_nonce(nonce) when is_binary(nonce) and byte_size(nonce) == 32, do: :ok
  def validate_nonce(_nonce), do: {:error, {:nonce, :malformed_nonce}}
end
