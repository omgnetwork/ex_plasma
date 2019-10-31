defmodule ExPlasma.Transactions.Deposit do
  @moduledoc """
  A Deposit `Transaction` type. We use this to
  send money into the contract to be used.
  """

  alias __MODULE__

  defstruct(
    inputs: [],
    outputs: [],
    metadata: <<0::160>>
  )

  @type t :: %__MODULE__{
          inputs: list(),
          outputs: list(map),
          metadata: binary()
        }

  @doc """
  Generate a new Deposit transaction struct which should:
    * have 0 inputs
    * have 1 output, containing the owner, currency, and amount

  ## Examples

  iex> ExPlasma.Transactions.Deposit.new("dog", "eth", 1, "dog money")
  %ExPlasma.Transactions.Deposit{
    inputs: [],
    metadata: "dog money",
    outputs: [%{amount: 1, currency: "eth", owner: "dog"}]
  }
  """
  def new(owner, currency, amount, metadata) do
    output = %{owner: owner, currency: currency, amount: amount}
    %__MODULE__{inputs: [], outputs: [output], metadata: metadata}
  end

  @doc """
  Encode the transaction with RLP

  ## Examples

    iex> owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    iex> currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    iex> amount = 1
    iex> metadata = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    iex> transaction = ExPlasma.Transactions.Deposit.new(owner, currency, amount, metadata)
    iex> ExPlasma.Transactions.Deposit.encode(transaction)
    <<248, 72, 1, 192, 240, 239, 1, 148, 29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 131, 48, 120, 49, 148, 29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
  """
  @spec encode(__MODULE__.t()) :: binary
  def encode(%__MODULE__{} = deposit), do: ExRLP.encode(deposit)

  @doc """
  Transforms the `Transaction` into a list, especially for encoding.

  ## Examples

    iex> owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    iex> currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    iex> amount = 1
    iex> metadata = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    iex> transaction = ExPlasma.Transactions.Deposit.new(owner, currency, amount, metadata)
    iex> ExPlasma.Transactions.Deposit.to_list(transaction)
    [
      1,
      [],
      [
        [
          1,
          <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65,
            226, 241, 55, 0, 110>>,
          <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
            241, 55, 0, 110>>,
          "0x1"
        ]
      ],
      <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
        241, 55, 0, 110>>
    ]
  """
  @spec to_list(__MODULE__.t()) :: list(any)
  def to_list(%__MODULE__{} = deposit), do: ExPlasma.Transaction.to_list(deposit)
end

defimpl ExRLP.Encode, for: ExPlasma.Transactions.Deposit do
  alias ExRLP.Encode
  alias ExPlasma.Transactions.Deposit

  @doc """
  Encodes a `Transaction` into RLP

  ## Examples

      Encodes a transaction
      iex(1)> transaction = %ExPlasma.Transactions.Deposit{}
      iex(2)> ExRLP.encode(transaction)
      <<227, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128, 128, 195,
        128, 128, 128, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128,
        128, 195, 128, 128, 128, 192>>
  """
  @spec encode(Deposit.t(), keyword) :: binary
  def encode(transaction, options \\ []) do
    transaction
    |> Deposit.to_list()
    |> Encode.encode(options)
  end
end

defimpl ExPlasma.Transaction, for: ExPlasma.Transactions.Deposit do
  alias ExPlasma.Transactions.Deposit

  import ExPlasma.Encoding, only: [to_hex: 1, to_binary: 1]

  # The associated value for the transaction type. It's a hard coded
  # value you can find on the contracts:
  @transaction_type 1

  # The associated value for the output type. It's a hard coded
  # value you can find on the contracts:
  @output_type 1

  @doc """
  Generates the RLP standardized list for RLP encoding for a Deposit transaction.
  Deposits do not contain an input and only 1 output. This ensures that we generate
  the list in the correct format and order.
  """
  @spec to_list(Deposit.t()) :: list()
  def to_list(%Deposit{inputs: [], outputs: [output], metadata: metadata}) do
    owner = to_binary(output[:owner])
    currency = to_binary(output[:currency])
    amount = to_hex(output[:amount])
    ordered_output = [@output_type, owner, currency, amount]
    [@transaction_type, [], [ordered_output], to_binary(metadata)]
  end

  @doc """
  Encode the transaction with RLP

  ## Examples

      iex(1)> transaction = %ExPlasma.Transactions.Deposit{}
      iex(2)> ExPlasma.Transactions.Deposit.encode(transaction)
      <<227, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128, 128, 195,
        128, 128, 128, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128,
        128, 195, 128, 128, 128, 192>>
  """
  @spec encode(Deposit.t()) :: binary
  def encode(%Deposit{} = deposit), do: ExRLP.encode(deposit)
end
