defmodule ExPlasma.Transaction.Type.Fee do
  @moduledoc false

  @behaviour ExPlasma.Transaction

  import ABI.TypeEncoder, only: [encode_raw: 2]

  alias ExPlasma.Encoding
  alias ExPlasma.Transaction

  @type address() :: <<_::160>>
  @type token() :: address()

  @type t() :: %{
          outputs: list(ExPlasma.Output),
          nonce: Encoding.hash_t()
        }

  @type validation_responses() ::
          {:ok, __MODULE__.t()}
          | {:error, {:outputs, :wrong_number_of_fee_outputs}}
          | {:error, {:outputs, :fee_output_amount_has_to_be_positive}}

  @tx_type 3

  defstruct outputs: [], nonce: nil

  @impl Transaction
  def new(), do: %__MODULE__{}

  @doc """
  Encode the given Transaction into an RLP encodeable list.

  ## Example

  iex> txn = %ExPlasma.Transaction{
  ...>  inputs: [%ExPlasma.Output{output_data: nil, output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}],
  ...>  metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
  ...>  outputs: [
  ...>    %ExPlasma.Output{
  ...>      output_data: %{amount: 1, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>,
  ...>        token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1
  ...>    }
  ...>  ],
  ...>  sigs: [],
  ...>  tx_data: <<0>>,
  ...>  tx_type: 1
  ...>}
  iex> ExPlasma.Transaction.Type.PaymentV1.to_rlp(txn)
  [[], <<1>>, [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>], [[<<1>>, [<<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, <<1>>]]], 0, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>]
  """
  @impl Transaction
  @spec to_rlp(__MODULE__.t()) :: list()
  def to_rlp(transaction) do
    [
      <<@tx_type>>,
      Enum.each(transaction.outputs, &ExPlasma.Output.to_rlp(&1)),
      transaction.nonce
    ]
  end

  @spec build_nonce(non_neg_integer(), token()) :: Encoding.hash_t()
  def build_nonce(blknum, token) do
    blknum_bytes = encode_raw([blknum], [{:uint, 256}])
    token_bytes = encode_raw([token], [:address])

    Encoding.keccak_hash(blknum_bytes <> token_bytes)
  end

  @doc """
  Decodes an RLP list into a Payment V1 Transaction.

  ## Example

  iex> rlp = [
  ...>  [],
  ...>  <<1>>,
  ...>  [<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>],
  ...>  [
  ...>    [
  ...>      <<1>>,
  ...>      [<<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, <<1>>]
  ...>    ]
  ...>  ],
  ...>  0,
  ...>  <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  ...>]
  iex> ExPlasma.Transaction.Type.PaymentV1.to_map(rlp)
  %ExPlasma.Transaction{
  	inputs: [
  		%ExPlasma.Output{
  			output_data: nil,
  			output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
  			output_type: nil
  		}
  	],
  	metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
  	outputs: [
  		%ExPlasma.Output{
  			output_data: %{
  				amount: 1,
  				output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153,
  					217, 206, 65, 226, 241, 55, 0, 110>>,
  				token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206,
  					65, 226, 241, 55, 0, 110>>
  			},
  			output_id: nil,
  			output_type: 1
  		}
  	],
  	sigs: [],
  	tx_data: 0,
  	tx_type: 1
  }
  """
  @impl Transaction
  @spec to_map(list()) :: __MODULE__.t()
  defp to_map([_tx_type, outputs, nonce]) do
    %__MODULE__{
      outputs: Enum.each(outputs, &ExPlasma.Output.decode(&1)),
      nonce: nonce
    }
  end

  @doc """
  Validates the Transaction.

  ## Example

  iex> txn = %{inputs: [%{output_data: [], output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0}, output_type: nil}], metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, outputs: [%{output_data: %{amount: <<0, 0, 0, 0, 0, 0, 0, 1>>, output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>, token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>}, output_id: nil, output_type: 1}], sigs: [], tx_data: <<0>>, tx_type: <<1>>}
  iex> {:ok, ^txn} = ExPlasma.Transaction.Type.PaymentV1.validate(txn)
  """
  @impl Transaction
  @spec validate(map()) :: validation_responses()
  def validate(%__MODULE__{} = transaction) do
    with true <- length(transaction.outputs) == 1 || {:error, {:outputs, :wrong_number_of_fee_outputs}},
         [output] <- outputs,
         :ok <- do_validate_amount(output) do
      {:ok, transaction}
    end
  end

  defp do_validate_amount(%{amount: amount}) when amount > 0, do: :ok
  defp do_validate_amount(_output), do: {:error, {:outputs, :fee_output_amount_has_to_be_positive}}
end
