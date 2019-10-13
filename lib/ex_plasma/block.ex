defmodule ExPlasma.Block do
  @moduledoc """
    Encapsulates the block data we receive from the contract. It returns two things:

    * hash - The merkle root block hash of the plasma blocks.
    * timestamp - the timestamp in seconds when the block is saved.
  """

  # TODO achiurizo
  # narrow the type definition
  @type t() :: %__MODULE__{
          hash: binary(),
          timestamp: binary()
        }

  defstruct [:hash, :timestamp]
end
