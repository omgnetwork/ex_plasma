defmodule ExPlasma.Output.Type.PaymentV1 do
  @moduledoc """
  Payment V1 output type.
  """
  @behaviour ExPlasma.Output

  alias ExPlasma.Output
  alias ExPlasma.Output.Type.AbstractPayment
  alias ExPlasma.Transaction.TypeMapper

  @type t() :: AbstractPayment.t()

  @payment_v1_type TypeMapper.output_type_for(:output_payment_v1)

  @impl Output
  defdelegate to_rlp(output), to: AbstractPayment

  @impl Output
  defdelegate to_map(rlp), to: AbstractPayment

  @impl Output
  def validate(%{output_type: @payment_v1_type} = output) do
    AbstractPayment.validate(output)
  end

  def validate(_output), do: {:error, {:output_type, :unrecognized_output_type}}
end
