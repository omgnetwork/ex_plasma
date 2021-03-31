defprotocol ExPlasma.TypedData do
  @moduledoc """
  EIP 712 signing encoding
  """

  @doc """
  The EIP712 encoded type data structure.
  """
  @spec encode(any(), maybe_improper_list()) :: maybe_improper_list() | binary()
  def encode(data, options \\ [])

  @doc """
  The keccak hash of the encoded data type.
  """
  @spec hash(any(), maybe_improper_list()) :: binary() | :not_implemented
  def hash(data, options \\ [])
end
