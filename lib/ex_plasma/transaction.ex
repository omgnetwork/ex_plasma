defmodule ExPlasma.Transaction do
  @moduledoc """
  The base transaction for now. There's actually a lot of different
  transaction types.

  TODO achiurizo
  fix this pile of poo
  """

  alias __MODULE__

  @type t :: %__MODULE__{
    inputs: list(__MODULE__.Input.t()),
    outputs: list(__MODULE__.Output.t()),
    metadata: binary()
  }

  @callback new(map()) :: struct()

  @callback to_list(struct()) :: list()

  @callback encode(struct()) :: binary()

  @callback transaction_type() :: non_neg_integer()

  @callback output_type() :: non_neg_integer()

  # @callback decode(binary) :: struct()

  defstruct(inputs: [], outputs: [], metadata: <<0::160>>)
end

defmodule ExPlasma.Transaction.Input do
  @moduledoc """
  An Input is an unspent output used in a transaction to generate a new
  unspent output.
  """

  @type t :: %__MODULE__{
    blknum: non_neg_integer(),
    txindex: non_neg_integer(),
    oindex: non_neg_integer()
  }

  defstruct [blknum: 0, txindex: 0, oindex: 0]
end

defmodule ExPlasma.Transaction.Output do
  @moduledoc """
  An output is created from an `input` and what is used to help
  move funds around the plasma system.
  """

  @type t :: %__MODULE__{
    owner: String.t() | non_neg_integer(),
    currency: String.t() | non_neg_integer(),
    amount: non_neg_integer(),
  }

  import ExPlasma.Encoding, only: [to_binary: 1]

  defstruct [owner: 0, currency: 0, amount: 0]

  @doc """
  Converts a given Output into an RLP-encodable list.

  ## Examples

  iex> owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
  iex> currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
  iex> amount = 1
  iex> output = %ExPlasma.Transaction.Output{owner: owner, currency: currency, amount: amount}
  iex> ExPlasma.Transaction.Output.to_list(output)
  [
  <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
    241, 55, 0, 110>>,
  <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
    241, 55, 0, 110>>,
  1
  ]
  """
  @spec to_list(__MODULE__.t() | map()) :: list()
  def to_list(%__MODULE__{owner: owner, currency: currency, amount: amount}), do:
    to_list(%{owner: owner, currency: currency, amount: amount})

  def to_list(%{owner: owner, currency: currency, amount: amount}), do:
    [to_binary(owner), to_binary(currency), amount]
end
