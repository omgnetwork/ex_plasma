defmodule ExPlasma.Output.Type.Fee do
  @moduledoc """
  Fee Output Type.
  """
  @behaviour ExPlasma.Output

  alias ExPlasma.Output
  alias ExPlasma.Output.Type.AbstractPayment
  alias ExPlasma.Transaction.TypeMapper

  @type t() :: AbstractPayment.t()

  @fee_type TypeMapper.output_type_for(:output_fee_token_claim)

  @impl Output
  defdelegate to_rlp(output), to: AbstractPayment

  @impl Output
  defdelegate to_map(rlp), to: AbstractPayment

  @impl Output
  def validate(%{output_type: @fee_type} = output) do
    AbstractPayment.validate(output)
  end

  def validate(_output), do: {:error, {:output_type, :unrecognized_output_type}}
end
