defmodule ExPlasma.Transactions.Deposit do
  @moduledoc """
  A Deposit `Transaction` type. We use this to
  send money into the contract to be used.
  """

  @behaviour ExPlasma.Transaction

  # The associated value for the transaction type. It's a hard coded
  # value you can find on the contracts:
  @transaction_type 1

  # The associated value for the output type. It's a hard coded
  # value you can find on the contracts:
  @output_type 1

  alias __MODULE__

  import ExPlasma.Encoding, only: [to_binary: 1]

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
    new(inputs: [], outputs: [output], metadata: metadata)
  end

  def new(inputs: inputs, outputs: outputs, metadata: metadata),
    do: %__MODULE__{inputs: inputs, outputs: outputs, metadata: metadata}

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
          1
        ]
      ],
      <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
        241, 55, 0, 110>>
    ]
  """
  @spec to_list(__MODULE__.t()) :: list()
  def to_list(%__MODULE__{inputs: [], outputs: [output], metadata: metadata}) do
    owner = to_binary(output[:owner])
    currency = to_binary(output[:currency])
    amount = output[:amount]
    ordered_output = [@output_type, owner, currency, amount]
    [@transaction_type, [], [ordered_output], to_binary(metadata)]
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
    <<248, 69, 1, 192, 237, 236, 1, 148, 29, 246, 47, 41, 27, 46, 150, 159, 176, 
      132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45, 41, 28, 
      46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 1, 148, 
      29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 
      55, 0, 110>>
  """
  @spec encode(__MODULE__.t()) :: binary
  def encode(%__MODULE__{} = deposit), do: ExRLP.encode(deposit)
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
    # TODO pattern match this portion so you can also pass in list already
    |> Deposit.to_list()
    |> Encode.encode(options)
  end
end
