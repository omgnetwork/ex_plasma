defmodule ExPlasma.Transaction2.Type.PaymentV1 do
  @moduledoc false

  @behaviour ExPlasma.Transaction2

  alias ExPlasma.Transaction2

  @type validation_responses() ::
  ExPlasma.Output.Type.PaymentV1.validation_responses()
  | {:error, {:inputs, :cannot_exceed_maximum_value}}
  | {:error, {:outputs, :cannot_exceed_maximum_value}}

  # The maximum input and outputs the Transaction can have.
  @output_limit 4

  @doc """
  Validates the Transaction.


  ## Example

  iex> txn = %{inputs: [%{output_data: [], output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}], metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, outputs: [%{output_data: %{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1}], sigs: [], tx_data: <<0>>, tx_type: <<1>>}
  iex> {:ok, ^txn} = ExPlasma.Transaction2.Type.PaymentV1.validate(txn)
  """
  @impl Transaction2
  @spec validate(map()) :: validation_responses()
  def validate(%{} = transaction) do
    with {:ok, _inputs} <- do_validate_total(:inputs, transaction.inputs, 0),
         {:ok, _outputs} <- do_validate_total(:outputs, transaction.outputs, 1) do
      {:ok, transaction}
    end
  end

  defp do_validate_total(field, list, min_limit) when length(list) > @output_limit do
    {:error, {field, :cannot_exceed_maximum_value}}
  end

  defp do_validate_total(field, list, min_limit) when length(list) < min_limit do
    {:error, {field, :cannot_subceed_minimum_value}}
  end

  defp do_validate_total(_field, list, _min_limit), do: {:ok, list}
end
