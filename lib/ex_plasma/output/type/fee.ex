defmodule ExPlasma.Output.Type.Fee do
  @moduledoc """
  Fee Output Type.
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
