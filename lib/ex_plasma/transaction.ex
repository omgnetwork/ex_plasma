defprotocol ExPlasma.Transaction do
  @moduledoc """
  The base transaction for now. There's actually a lot of different
  transaction types.

  TODO achiurizo
  fix this pile of poo
  """

  @doc """
  Converts the given transaction type into a RLP encoded
  data that can be sent to the contract.
  """
  def encode(transaction)

  @doc """
  Converts the given RLP encoded data back into the struct.
  """
  def decode(data)
end
