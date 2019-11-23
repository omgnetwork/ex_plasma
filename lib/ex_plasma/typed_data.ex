defprotocol ExPlasma.TypedData do
  @doc """
  The EIP712 encoded type data structure.
  """
  def encode(data)

  @doc """
  The EIP712 encoded type data structure.
  """
  def encode_input(data)
  def encode_output(data)

  @doc """
  The keccak hash of the encoded data type.
  """
  def hash(data)
end
