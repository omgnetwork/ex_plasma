defimpl ExPlasma.TypedData, for: ExPlasma.Transaction do
  alias ExPlasma.Crypto
  alias ExPlasma.Encoding
  alias ABI.TypeEncoder
  alias ExPlasma.Configuration
  alias ExPlasma.TypedData

  # Prefix and version byte motivated by http://eips.ethereum.org/EIPS/eip-191
  @eip_191_prefix <<0x19, 0x01>>

  @domain_signature "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
  @signature "Transaction(uint256 txType,Input[] inputs,Output[] outputs,uint256 txData,bytes32 metadata)"
  @output_signature "Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)"
  @input_signature "Input(uint256 blknum,uint256 txindex,uint256 oindex)"

  # The full encoded signature for the transaction
  @encoded_signature Crypto.keccak_hash(@signature <> @input_signature <> @output_signature)

  def encode(transaction, _options) do
    encoded_inputs =
      transaction.inputs |> Enum.map(&encode_as_input/1) |> List.flatten() |> Enum.join() |> Crypto.keccak_hash()

    encoded_outputs =
      transaction.outputs |> Enum.map(&encode_as_output/1) |> List.flatten() |> Enum.join() |> Crypto.keccak_hash()

    encoded_transaction_type = TypeEncoder.encode_raw([transaction.tx_type], [{:uint, 256}])
    encoded_transaction_data = TypeEncoder.encode_raw([transaction.tx_data], [{:uint, 256}])
    encoded_metadata = TypeEncoder.encode_raw([transaction.metadata], [{:bytes, 32}])

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

  def hash(%{} = transaction, options) do
    transaction
    |> encode(options)
    |> hash(options)
  end

  def hash([prefix, domain_separator | encoded_transaction], _options) do
    Crypto.keccak_hash(prefix <> hash_domain(domain_separator) <> hash_encoded(encoded_transaction))
  end

  defp encode_as_input(output), do: TypedData.encode(output, as: :input)
  defp encode_as_output(output), do: TypedData.encode(output, as: :output)

  defp hash_encoded([signature, transaction_type, inputs, outputs, transaction_data, metadata]) do
    [
      signature,
      transaction_type,
      inputs,
      outputs,
      transaction_data,
      metadata
    ]
    |> List.flatten()
    |> Enum.join()
    |> Crypto.keccak_hash()
  end

  # defp hash_inputs(inputs) do
  #   inputs
  #   |> Enum.map(&hash_output/1)
  #   |> List.flatten()
  #   |> Enum.join()
  #   |> Crypto.keccak_hash()
  # end

  # defp hash_outputs(outputs) do
  #   outputs
  #   |> Enum.map(&hash_output/1)
  #   |> List.flatten()
  #   |> Enum.join()
  #   |> Crypto.keccak_hash()
  # end

  # defp hash_output([signature | encoded_list]) do
  #   data = [Crypto.keccak_hash(signature) | encoded_list]

  #   data
  #   |> Enum.join()
  #   |> Crypto.keccak_hash()
  # end

  defp domain_separator() do
    domain = Configuration.eip_712_domain()

    [
      @domain_signature,
      domain.name,
      domain.version,
      domain.verifying_contract,
      domain.salt
    ]
  end

  defp hash_domain([signature, name, version, verifying_contract, salt]) do
    [
      Crypto.keccak_hash(signature),
      Crypto.keccak_hash(name),
      Crypto.keccak_hash(version),
      TypeEncoder.encode_raw([Encoding.to_binary!(verifying_contract)], [:address]),
      TypeEncoder.encode_raw([Encoding.to_binary!(salt)], [{:bytes, 32}])
    ]
    |> Enum.join()
    |> Crypto.keccak_hash()
  end
end
