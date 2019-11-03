defmodule ExPlasma.Transaction do
  @moduledoc """
  The base transaction for now. There's actually a lot of different
  transaction types.

  TODO achiurizo
  fix this pile of poo
  """

  @callback new(map()) :: struct()

  @callback to_list(struct()) :: list()

  @callback encode(struct()) :: binary()

  # @callback decode(binary) :: struct()
end
