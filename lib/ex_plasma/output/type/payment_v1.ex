defmodule ExPlasma.Output.Type.PaymentV1 do
  @moduledoc """
  Payment V1 Output Type.
  """

  alias ExPlasma.Output.Type.GenericPayment

  defdelegate to_rlp(output), to: GenericPayment

  defdelegate to_map(rlp), to: GenericPayment

  defdelegate validate(output), to: GenericPayment
end
