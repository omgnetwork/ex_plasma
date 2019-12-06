defimpl ExPlasma.TypedData,
  for: [ExPlasma.Transaction, ExPlasma.Transactions.Deposit, ExPlasma.Transactions.Payment] do
  alias ExPlasma.Encoding
  alias ExPlasma.TypedData
  alias ExPlasma.Utxo

  # Prefix and version byte motivated by http://eips.ethereum.org/EIPS/eip-191
  @eip_191_prefix <<0x19, 0x01>>

  @domain_signature "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
  @signature "Transaction(uint256 txType,Input input0,Input input1,Input input2,Input input3,Output output0,Output output1,Output output2,Output output3,bytes32 metadata)"
  @output_signature "Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)"
  @input_signature "Input(uint256 blknum,uint256 txindex,uint256 oindex)"

  # NB: Currently we only support 1 type of transaction: Payment.
  @max_utxo_count 4
  @empty_metadata <<0::256>>

  # Pre-computed hashes for hashing
  @empty_input_hash %Utxo{} |> TypedData.hash(as: :input)
  @empty_output_hash %Utxo{output_type: 0} |> TypedData.hash(as: :output)

  def encode(%module{inputs: inputs, outputs: outputs, metadata: metadata}, _options) do
    encoded_inputs = Enum.map(inputs, &encode_as_input/1)
    encoded_outputs = Enum.map(outputs, &encode_as_output/1)

    transaction_type = module.transaction_type()
    encoded_transaction_type = ABI.TypeEncoder.encode_raw([transaction_type], [{:uint, 256}])
    encoded_signature = @signature <> @input_signature <> @output_signature

    [
      @eip_191_prefix,
      domain_separator(),
      encoded_signature,
      encoded_transaction_type,
      encoded_inputs,
      encoded_outputs,
      metadata || @empty_metadata
    ]
  end

  def hash(%{} = transaction, options), do: transaction |> encode(options) |> hash(options)

  def hash([prefix, domain_separator | encoded_transaction], _options),
    do:
      Encoding.keccak_hash(
        prefix <> hash_domain(domain_separator) <> hash_encoded(encoded_transaction)
      )

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
      Encoding.keccak_hash(signature),
      Encoding.keccak_hash(name),
      Encoding.keccak_hash(version),
      ABI.TypeEncoder.encode_raw([Encoding.to_binary(verifying_contract)], [:address]),
      ABI.TypeEncoder.encode_raw([Encoding.to_binary(salt)], [{:bytes, 32}])
    ]
    |> Enum.join()
    |> Encoding.keccak_hash()
  end

  defp hash_encoded([signature, transaction_type, inputs, outputs, metadata]) do
    list = [
      signature, 
      transaction_type,
      hash_inputs(inputs),
      hash_outputs(outputs),
      metadata
    ] 

    IO.inspect(list, limit: :infinity)

    list
    |> List.flatten()
    |> Enum.join()
    |> Encoding.keccak_hash()
  end

  defp encode_as_input(utxo), do: TypedData.encode(utxo, as: :input)
  defp encode_as_output(utxo), do: TypedData.encode(utxo, as: :output)

  defp hash_inputs(inputs) do
    inputs
    |> Stream.map(&hash_utxo/1)
    |> Stream.concat(Stream.cycle([@empty_input_hash]))
    |> Enum.take(@max_utxo_count)
  end

  defp hash_outputs(outputs) do
    outputs
    |> Stream.map(&hash_utxo/1)
    |> Stream.concat(Stream.cycle([@empty_output_hash]))
    |> Enum.take(@max_utxo_count)
  end

  defp hash_utxo([signature | encoded_list]),
    do:
      ([Encoding.keccak_hash(signature)] ++ encoded_list)
      |> Enum.join()
      |> Encoding.keccak_hash()
end
