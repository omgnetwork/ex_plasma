defimpl ExPlasma.TypedData, for: ExPlasma.Output do
  import ExPlasma.Crypto, only: [keccak_hash: 1]
  import ABI.TypeEncoder, only: [encode_raw: 2]

  alias ExPlasma.Output

  @output_signature "Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)"
  @input_signature "Input(uint256 blknum,uint256 txindex,uint256 oindex)"

  @spec encode(Output.t(), as: atom()) :: list()
  def encode(output, as: :input), do: do_to_rlp_id(output.output_id)
  def encode(output, as: :output), do: do_encode(output)

  @spec hash(Output.t(), [{:as, :input | :output}, ...]) :: <<_::256>>
  def hash(output, options), do: output |> encode(options) |> do_hash(options)

  defp do_encode(%{output_type: type, output_data: data}) do
    [
      @output_signature,
      encode_raw([type], [{:uint, 256}]),
      encode_raw([data.output_guard], [{:bytes, 20}]),
      encode_raw([data.token], [:address]),
      encode_raw([data.amount], [{:uint, 256}])
    ]
  end

  defp do_to_rlp_id(%{blknum: blknum, txindex: txindex, oindex: oindex}) do
    [
      @input_signature,
      encode_raw([blknum], [{:uint, 256}]),
      encode_raw([txindex], [{:uint, 256}]),
      encode_raw([oindex], [{:uint, 256}])
    ]
  end

  defp do_hash([signature | encoded_list], _options) do
    data = [keccak_hash(signature) | encoded_list]

    data
    |> Enum.join()
    |> keccak_hash()
  end
end
