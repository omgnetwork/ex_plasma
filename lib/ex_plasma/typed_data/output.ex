defimpl ExPlasma.TypedData, for: ExPlasma.Output do
  alias ExPlasma.Crypto
  alias ABI.TypeEncoder
  alias ExPlasma.Output

  @output_signature Crypto.keccak_hash("Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)")
  @input_signature Crypto.keccak_hash("Input(uint256 blknum,uint256 txindex,uint256 oindex)")

  @spec encode(Output.t(), as: atom()) :: list()
  def encode(output, as: :input), do: do_to_rlp_id(output.output_id)
  def encode(output, as: :output), do: do_encode(output)

  @spec hash(Output.t(), [{:as, :input | :output}, ...]) :: :not_implemented
  def hash(_output, _options), do: :not_implemented

  defp do_encode(%{output_type: type, output_data: data}) do
    [
      @output_signature,
      TypeEncoder.encode_raw([type], [{:uint, 256}]),
      TypeEncoder.encode_raw([data.output_guard], [{:bytes, 20}]),
      TypeEncoder.encode_raw([data.token], [:address]),
      TypeEncoder.encode_raw([data.amount], [{:uint, 256}])
    ]
    |> Enum.join()
    |> Crypto.keccak_hash()
  end

  defp do_to_rlp_id(%{blknum: blknum, txindex: txindex, oindex: oindex}) do
    [
      @input_signature,
      TypeEncoder.encode_raw([blknum], [{:uint, 256}]),
      TypeEncoder.encode_raw([txindex], [{:uint, 256}]),
      TypeEncoder.encode_raw([oindex], [{:uint, 256}])
    ]
    |> Enum.join()
    |> Crypto.keccak_hash()
  end

  # defp do_hash([signature | encoded_list], _options) do
  #   data = [Crypto.keccak_hash(signature) | encoded_list]

  #   data
  #   |> Enum.join()
  #   |> Crypto.keccak_hash()
  # end
end
