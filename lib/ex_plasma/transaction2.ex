defmodule ExPlasma.Transaction2 do
  @moduledoc false

  alias ExPlasma.Output

  @type sigs() :: list(binary()) | []
  @type outputs() :: list(Output.t()) | []
  @type metadata :: <<_::160>> | nil

  @type t() :: %{
    sigs: sigs(),
    inputs: outputs(),
    outputs: outputs(),
    metadata: metadata()
  }

  @callback decode(any()) :: map()
  @callback encode(map()) :: any()
  @callback validate(any()) :: {:ok, map()} | {:error, {atom(), atom()}}

  @transaction_types %{
    1 => ExPlasma.Transaction2.Type.PaymentV1
  }

  @doc """
  Encode the given Transaction into an RLP encodeable list.

  ## Example

  iex> txn = %{inputs: [%{output_data: [], output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}], metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, outputs: [%{output_data: %{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1}], sigs: [], tx_data: <<0>>, tx_type: <<1>>}
  iex> ExPlasma.Transaction2.encode(txn)
  <<248, 74, 192, 1, 193, 128, 239, 174, 237, 1, 235, 148, 29, 246, 47, 41, 27,
    46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46,
    38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
    0, 110, 1, 0, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0>>
  """
  def encode(%{tx_type: <<tx_type>>} = transaction), do: @transaction_types[tx_type].encode(transaction) |> ExRLP.encode()

  @doc """
  Decode the given RLP list into a Transaction.

  ## Example

  iex> rlp = <<248, 74, 192, 1, 193, 128, 239, 174, 237, 1, 235, 148, 29, 246, 47, 41, 27,
  ...>   46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46,
  ...>   38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
  ...>   0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...>   0>>
  iex> ExPlasma.Transaction2.decode(rlp)
  %{
    inputs: [
      %{output_data: [], output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}
    ], 
    metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    outputs: [%{output_data: %{amount: <<1>>, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1}],
    sigs: [], 
    tx_data: "",
    tx_type: <<1>>
  }
  """
  @spec decode(list()) :: t()
  def decode(data), do: data |> ExRLP.decode() |> do_decode()
  defp do_decode([_tx_type, _inputs, _outputs, _tx_data, _metadata] = rlp), do: do_decode([[] | rlp])
  defp do_decode([_sigs, <<tx_type>>, _inputs, _outputs, _tx_data, _metadata] = rlp), do: @transaction_types[tx_type].decode(rlp)

  @doc """
  Validate a Transation. This will check the inputs, outputs, and run
  the validation through the matching transaction type.


  ## Example

  iex> txn = %{inputs: [%{output_data: [], output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}], metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, outputs: [%{output_data: %{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1}], sigs: [], tx_data: <<0>>, tx_type: <<1>>}
  iex> {:ok, ^txn} = ExPlasma.Transaction2.validate(txn)
  """
  def validate(%{} = transaction) do
    with {:ok, _inputs} <- validate_output(transaction.inputs),
         {:ok, _outputs} <- validate_output(transaction.outputs),
         {:ok, _transaaction} <- do_validate(transaction) do
      {:ok, transaction}
    end
  end

  defp validate_output([output | rest]) do
    with {:ok, _whatever} <- ExPlasma.Output.validate(output), do: validate_output(rest)
  end

  defp validate_output([]), do: {:ok, []}

  defp do_validate(%{tx_type: <<type>>} = transaction), do: @transaction_types[type].validate(transaction)
end
