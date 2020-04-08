defmodule ExPlasma.Transaction2 do
  @moduledoc false

  alias ExPlasma.Output

  @callback decode(any()) :: map()
  @callback encode(map()) :: any()
  @callback validate(any()) :: {:ok, map()} | {:error, {atom(), atom()}}


  @transaction_types %{
    1 => []
  }

  @empty_transaction_data 0
  @empty_metadata <<0::256>>


  @doc """

  ## Example

  iex> rlp = [
  ...>  ExPlasma.payment_v1(),
  ...>  [<<0>>],
  ...>  [
  ...>    [
  ...>      ExPlasma.payment_v1(),
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
  iex> ExPlasma.Transaction2.new(rlp)
  %{inputs: [%{output_data: [], output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}], metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, outputs: [%{output_data: %{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1}], sigs: [], tx_data: <<0>>, tx_type: <<1>>}
  """
  def new(data), do: do_new(data)


  def validate(%{} = transaction) do
    with {:ok, _inputs} <- validate_output(transaction.inputs),
         {:ok, _outputs} <- validate_output(transaction.outputs),
         {:ok, _transaaction} <- do_validate(transaction) do
    end
  end

  defp validate_output([output | rest]) do
    with {:ok, _whatever} <- validate_output(output), do: validate_output(rest)
  end

  defp validate_output([]), do: {:ok, []}

  defp do_validate(%{tx_type: type} = transaction), do: @transaction_types[type].validate(transaction)

  defp do_new([tx_type, inputs, outputs, tx_data, metadata]),
    do: do_new([[], tx_type, inputs, outputs, tx_data, metadata])

  defp do_new([sigs, tx_type, inputs, outputs, tx_data, metadata]) do
    %{
      sigs: sigs,
      tx_type: tx_type,
      inputs: Enum.map(inputs, &ExPlasma.Output.new/1),
      outputs: Enum.map(outputs, &ExPlasma.Output.new/1),
      tx_data: tx_data,
      metadata: metadata
    }
  end
end
