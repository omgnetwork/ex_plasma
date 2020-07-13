defprotocol ExPlasma.Transaction.Protocol do
  @moduledoc """
  Generic protocol for all supported transactions
  """

  alias ExPlasma.Output

  @doc """
  Transforms structured data into RLP-structured (encodable) list of fields
  """
  @spec to_rlp(t()) :: list()
  def to_rlp(tx)

  @doc """
  Decodes an RLP list into a structure matching the type provided.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec to_map(t(), list()) :: {:ok, t()} | {:error, atom}
  def to_map(tx, rlp)

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
  Returns the tx type of the transaction
  """
  @spec get_tx_type(t()) :: pos_integer()
  def get_tx_type(tx)

  @doc """
  Statelessly validate the transaction
  """
  @spec validate(t()) :: :ok | {:error, atom(), atom()}
  def validate(tx)
end
