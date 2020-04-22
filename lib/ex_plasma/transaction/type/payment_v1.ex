defmodule ExPlasma.Transaction.Type.PaymentV1 do
  @moduledoc false

  @behaviour ExPlasma.Transaction

  alias ExPlasma.Transaction

  @type validation_responses() ::
          ExPlasma.Output.Type.PaymentV1.validation_responses()
          | {:error, {:inputs, :cannot_exceed_maximum_value}}
          | {:error, {:outputs, :cannot_exceed_maximum_value}}

  # The maximum input and outputs the Transaction can have.
  @output_limit 4

  @tx_type 1

  # Currently, the plasma-contracts don't have these
  # values set, so we mark them explicitly empty.
  @empty_tx_data 0
  @empty_metadata <<0::256>>

  @doc """
  Encode the given Transaction into an RLP encodeable list.

  ## Example

  iex> txn = %{inputs: [%{output_data: nil, output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}], metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, outputs: [%{output_data: %{amount: 1, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1}], sigs: [], tx_data: <<0>>, tx_type: 1}
  iex> ExPlasma.Transaction.Type.PaymentV1.to_rlp(txn)
  [[], <<1>>, [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>], [[<<1>>, [<<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, <<1>>]]], 0, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>]
  """
  @impl Transaction
  @spec to_rlp(Transaction.t()) :: list()
  def to_rlp(%{} = transaction) do
    [
      transaction.sigs,
      <<@tx_type>>,
      Enum.map(transaction.inputs, &ExPlasma.Output.to_rlp_id/1),
      Enum.map(transaction.outputs, &ExPlasma.Output.to_rlp/1),
      @empty_tx_data,
      transaction.metadata || @empty_metadata
    ]
  end

  @doc """
  Decodes an RLP list into a Payment V1 Transaction.

  ## Example

  iex> rlp = [
  ...>  [], 
  ...>  <<1>>, 
  ...>  [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>], 
  ...>  [
  ...>    [
  ...>      <<1>>, 
  ...>      [<<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, <<1>>]
  ...>    ]
  ...>  ], 
  ...>  0,
  ...>  <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  ...>]
  iex> ExPlasma.Transaction.Type.PaymentV1.to_map(rlp)
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
  @impl Transaction
  @spec to_map(list()) :: Transaction.t()
  def to_map(rlp), do: do_to_map(rlp)

  defp do_to_map([sigs, tx_type, inputs, outputs, "", metadata]),
    do: do_to_map([sigs, tx_type, inputs, outputs, 0, metadata])

  defp do_to_map([sigs, <<tx_type>>, inputs, outputs, tx_data, metadata]),
    do: do_to_map([sigs, tx_type, inputs, outputs, tx_data, metadata])

  defp do_to_map([sigs, tx_type, inputs, outputs, tx_data, metadata]) do
    %{
      sigs: sigs,
      tx_type: tx_type,
      inputs: Enum.map(inputs, &ExPlasma.Output.decode_id/1),
      outputs: Enum.map(outputs, &ExPlasma.Output.decode/1),
      tx_data: tx_data,
      metadata: metadata
    }
  end

  @doc """
  Validates the Transaction.

  ## Example

  iex> txn = %{inputs: [%{output_data: [], output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}], metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, outputs: [%{output_data: %{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1}], sigs: [], tx_data: <<0>>, tx_type: <<1>>}
  iex> {:ok, ^txn} = ExPlasma.Transaction.Type.PaymentV1.validate(txn)
  """
  @impl Transaction
  @spec validate(map()) :: validation_responses()
  def validate(%{} = transaction) do
    with {:ok, _inputs} <- do_validate_total(:inputs, transaction.inputs, 0),
         {:ok, _outputs} <- do_validate_total(:outputs, transaction.outputs, 1) do
      {:ok, transaction}
    end
  end

  defp do_validate_total(field, list, _min_limit) when length(list) > @output_limit do
    {:error, {field, :cannot_exceed_maximum_value}}
  end

  defp do_validate_total(field, list, min_limit) when length(list) < min_limit do
    {:error, {field, :cannot_subceed_minimum_value}}
  end

  defp do_validate_total(_field, list, _min_limit), do: {:ok, list}
end
