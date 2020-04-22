defimpl ExPlasma.TypedData, for: ExPlasma.Transaction do
  import ExPlasma.Encoding, only: [to_binary: 1, keccak_hash: 1]
  import ABI.TypeEncoder, only: [encode_raw: 2]

  alias ExPlasma.Output
  alias ExPlasma.TypedData

  # Prefix and version byte motivated by http://eips.ethereum.org/EIPS/eip-191
  @eip_191_prefix <<0x19, 0x01>>

  @domain_signature "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
  @signature "Transaction(uint256 txType,Input input0,Input input1,Input input2,Input input3,Output output0,Output output1,Output output2,Output output3,uint256 txData,bytes32 metadata)"
  @output_signature "Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)"
  @input_signature "Input(uint256 blknum,uint256 txindex,uint256 oindex)"

  # The full encoded signature for the transaction
  @encoded_signature @signature <> @input_signature <> @output_signature

  # NB: Currently we only support 1 type of transaction: Payment.
  @max_output_count 4

  @empty_input Output.decode_id(<<0>>)
  @empty_input_hash TypedData.hash(@empty_input, as: :input)

  @empty_output %Output{
    output_type: 0,
    output_data: %{output_guard: <<0::160>>, token: <<0::160>>, amount: 0}
  }
  @empty_output_hash TypedData.hash(@empty_output, as: :output)

  def encode(%{} = transaction, _options) do
    encoded_inputs = Enum.map(transaction.inputs, &encode_as_input/1)
    encoded_outputs = Enum.map(transaction.outputs, &encode_as_output/1)
    encoded_transaction_type = encode_raw([transaction.tx_type], [{:uint, 256}])
    encoded_transaction_data = encode_raw([transaction.tx_data], [{:uint, 256}])
    encoded_metadata = encode_raw([transaction.metadata], [{:bytes, 32}])

    [
      @eip_191_prefix,
      domain_separator(),
      @encoded_signature,
      encoded_transaction_type,
      encoded_inputs,
      encoded_outputs,
      encoded_transaction_data,
      encoded_metadata
    ]
  end

  def hash(%{} = transaction, options), do: transaction |> encode(options) |> hash(options)

  def hash([prefix, domain_separator | encoded_transaction], _options),
    do: keccak_hash(prefix <> hash_domain(domain_separator) <> hash_encoded(encoded_transaction))

  defp domain_separator() do
    domain = Application.get_env(:ex_plasma, :eip_712_domain)

    [
      @domain_signature,
      domain[:name],
      domain[:version],
      domain[:verifying_contract],
      domain[:salt]
    ]
  end

  defp hash_domain([signature, name, version, verifying_contract, salt]) do
    [
      keccak_hash(signature),
      keccak_hash(name),
      keccak_hash(version),
      encode_raw([to_binary(verifying_contract)], [:address]),
      encode_raw([to_binary(salt)], [{:bytes, 32}])
    ]
    |> Enum.join()
    |> keccak_hash()
  end

  defp hash_encoded([signature, transaction_type, inputs, outputs, transaction_data, metadata]) do
    [
      keccak_hash(signature),
      transaction_type,
      hash_inputs(inputs),
      hash_outputs(outputs),
      transaction_data,
      metadata
    ]
    |> List.flatten()
    |> Enum.join()
    |> keccak_hash()
  end

  defp encode_as_input(output), do: TypedData.encode(output, as: :input)
  defp encode_as_output(output), do: TypedData.encode(output, as: :output)

  defp hash_inputs(inputs) do
    inputs
    |> Stream.map(&hash_output/1)
    |> Stream.concat(Stream.cycle([@empty_input_hash]))
    |> Enum.take(@max_output_count)
  end

  defp hash_outputs(outputs) do
    outputs
    |> Stream.map(&hash_output/1)
    |> Stream.concat(Stream.cycle([@empty_output_hash]))
    |> Enum.take(@max_output_count)
  end

  defp hash_output([signature | encoded_list]) do
    data = [keccak_hash(signature) | encoded_list]

    data
    |> Enum.join()
    |> keccak_hash()
  end
end
