defmodule ExPlasma.Output.Type.Fee do
  @moduledoc """
  Fee Output Type.
  """

  alias ExPlasma.Output.Type.AbstractPayment

  @type t() :: AbstractPayment.t()

  defdelegate to_rlp(output), to: AbstractPayment

  defdelegate to_map(rlp), to: AbstractPayment

  defdelegate validate(output), to: AbstractPayment
end
