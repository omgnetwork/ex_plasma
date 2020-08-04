defmodule ExPlasma.Output.Type.PaymentV1 do
  @moduledoc """
  Payment V1 Output Type.
  """

  alias ExPlasma.Output.Type.AbstractPayment

  @type t() :: AbstractPayment.t()

  defdelegate to_rlp(output), to: AbstractPayment

  defdelegate to_map(rlp), to: AbstractPayment

  defdelegate validate(output), to: AbstractPayment
end
