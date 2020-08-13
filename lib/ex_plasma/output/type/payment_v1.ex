defmodule ExPlasma.Output.Type.PaymentV1 do
  @moduledoc """
  Payment V1 output type.
  """
  @behaviour ExPlasma.Output

  alias ExPlasma.Output
  alias ExPlasma.Output.Type.AbstractPayment

  @type t() :: AbstractPayment.t()

  @impl Output
  defdelegate to_rlp(output), to: AbstractPayment

  @impl Output
  defdelegate to_map(rlp), to: AbstractPayment

  @impl Output
  defdelegate validate(output), to: AbstractPayment
end
