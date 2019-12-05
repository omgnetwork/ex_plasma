defimpl ExPlasma.TypedData,
  for: [ExPlasma.Transaction, ExPlasma.Transactions.Deposit, ExPlasma.Transactions.Payment] do
  alias ExPlasma.Encoding
  alias ExPlasma.TypedData
  alias ExPlasma.Utxo

  # Prefix and version byte motivated by http://eips.ethereum.org/EIPS/eip-191
  @eip_191_prefix <<0x19, 0x01>>

  @domain_signature "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
  @signature "Transaction(uint256 txType,Input input0,Input input1,Input input2,Input input3,Output output0,Output output1,Output output2,Output output3,bytes32 metadata)"

  # NB: Currently we only support 1 type of transaction: Payment.
  @max_utxo_count 4
  @empty_metadata <<0::256>>

  def encode(%module{inputs: inputs, outputs: outputs, metadata: metadata}, _options) do
    encoded_inputs = inputs |> fill_list() |> Enum.map(&encode_as_input/1)
    encoded_outputs = outputs |> fill_list() |> Enum.map(&encode_as_output/1)

    transaction_type = module.transaction_type()
    encoded_transaction_type = ABI.TypeEncoder.encode_raw([transaction_type], [{:uint, 256}])

    [
      @eip_191_prefix,
      domain_separator(),
      @signature,
      encoded_transaction_type,
      encoded_inputs,
      encoded_outputs,
      metadata || @empty_metadata
    ]
  end

  def hash(%{} = transaction), do: transaction |> encode([]) |> hash()

  def hash([prefix, domain_separator | encoded_transaction]),
    do: Encoding.keccak_hash(prefix <> hash_domain(domain_separator) <> hash_encoded(encoded_transaction))

  defp domain_separator() do
    domain = Application.get_env(:ex_plasma, :eip_712_domain)
    verifying_contract = domain[:verifying_contract] |> Encoding.to_binary()
    salt = domain[:salt] |> Encoding.to_binary()

    [
      @domain_signature,
      domain[:name],
      domain[:version],
      ABI.TypeEncoder.encode_raw([verifying_contract], [:address]),
      ABI.TypeEncoder.encode_raw([salt], [{:bytes, 32}])
    ]
  end

  defp hash_domain([signature, name, version, verifying_contract, salt]) do
    [
      Encoding.keccak_hash(signature),
      Encoding.keccak_hash(name),
      Encoding.keccak_hash(version),
      verifying_contract,
      salt
    ]
    |> Enum.join()
    |> Encoding.keccak_hash()
  end

  defp hash_encoded(eip712_list) when is_list(eip712_list),
    do:
      eip712_list
      |> List.flatten()
      |> Enum.join()
      |> Encoding.keccak_hash()

  defp encode_as_input(utxo), do: TypedData.encode(utxo, as: :input)
  defp encode_as_output(utxo), do: TypedData.encode(utxo, as: :output)

  defp fill_list(list), do: List.duplicate(%Utxo{}, @max_utxo_count - length(list))
end
