defprotocol ExPlasma.TypedData do
  @moduledoc """
  EIP 712 signing encoding
  """

  @doc """
  The EIP712 encoded type data structure.
  """
  @spec encode(any(), maybe_improper_list()) :: any()
  def encode(data, options \\ [])

  @doc """
  The keccak hash of the encoded data type.
  """
  @spec encode(any()) :: binary()
  def hash(data, options \\ [])
end
