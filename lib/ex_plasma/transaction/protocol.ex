defprotocol ExPlasma.Transaction.Protocol do
  @moduledoc """
  Generic protocol for all supported transactions
  """

  alias ExPlasma.Output

  @doc """
  Transforms structured data into RLP-structured (encodable) list of fields
  """
  @spec to_rlp(t()) :: list(any())
  def to_rlp(tx)

  @doc """
  Decodes an RLP list into a structure matching the type provided.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec to_map(list(any())) :: {:ok, t()} | {:error, atom}
  def to_map(rlp)

  @doc """
  List of inputs this transaction intends to spend
  """
  @spec get_inputs(t()) :: list(Output.t())
  def get_inputs(tx)

  @doc """
  List of outputs this transaction intends to create
  """
  @spec get_outputs(t()) :: list(Output.t())
  def get_outputs(tx)

  @doc """
  Statelessly validate the transaction
  """
  @spec validate(t()) :: {:ok, t()} | {:error, atom}
  def validate(tx)
end
