defimpl ExPlasma.TypedData, for: ExPlasma.Utxo do
  alias ExPlasma.Encoding
  alias ExPlasma.Utxo

  @output_signature "Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)"
  @input_signature "Input(uint256 blknum,uint256 txindex,uint256 oindex)"

  @doc """
  """
  @spec encode(ExPlasma.Utxo.t(), any()) :: list()
  def encode(utxo, as: :input), do: utxo |> Utxo.to_input_rlp() |> do_encode()
  def encode(utxo, as: :output), do: utxo |> Utxo.to_output_rlp() |> do_encode()
  def encode(utxo, _options), do: utxo |> Utxo.to_rlp() |> do_encode()

  def hash(%{} = utxo, options), do: utxo |> encode(options) |> hash(options)

  def hash([signature | encoded_list], _options) do
    data = [Encoding.keccak_hash(signature) | encoded_list]

    data
    |> Enum.join()
    |> Encoding.keccak_hash()
  end

  defp do_encode([output_type, [owner, currency, amount]]) do
    [
      @output_signature,
      ABI.TypeEncoder.encode_raw([:binary.decode_unsigned(output_type)], [{:uint, 256}]),
      ABI.TypeEncoder.encode_raw([owner], [{:bytes, 20}]),
      ABI.TypeEncoder.encode_raw([currency], [:address]),
      ABI.TypeEncoder.encode_raw([amount], [{:uint, 256}])
    ]
  end

  defp do_encode(encoded_utxo_pos) when is_binary(encoded_utxo_pos) do
    {:ok, %Utxo{blknum: blknum, txindex: txindex, oindex: oindex}} = Utxo.new(encoded_utxo_pos)

    [
      @input_signature,
      ABI.TypeEncoder.encode_raw([blknum], [{:uint, 256}]),
      ABI.TypeEncoder.encode_raw([txindex], [{:uint, 256}]),
      ABI.TypeEncoder.encode_raw([oindex], [{:uint, 256}])
    ]
  end
end
