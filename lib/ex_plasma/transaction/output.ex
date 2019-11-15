defmodule ExPlasma.Transaction.Output do
  @moduledoc """
  An output is created from an `input` and what is used to help
  move funds around the plasma system.
  """

  @type t :: %__MODULE__{
          owner: String.t() | non_neg_integer(),
          currency: String.t() | non_neg_integer(),
          amount: non_neg_integer()
        }

  import ExPlasma.Encoding, only: [to_binary: 1]

  defstruct owner: 0, currency: 0, amount: 0

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
  <<0, 0, 0, 0, 0, 0, 0, 1>>
  ]
  """
  @spec to_list(__MODULE__.t() | map()) :: list()
  def to_list(%__MODULE__{} = output), do: output |> Map.from_struct() |> to_list()

  # TODO
  # Add guards to cover the values coming in
  def to_list(%{owner: owner, currency: currency, amount: amount}),
    do: [to_binary(owner), to_binary(currency), <<amount::integer-size(64)>>]
end
