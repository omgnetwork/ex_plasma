defprotocol ExPlasma.TypedData do
  @doc """
  The EIP712 encoded type data structure.
  """
  def encode(data)

  @doc """
  The keccak hash of the encoded data type.
  """
  def hash(data)
end
