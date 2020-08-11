defmodule ExPlasma.Transaction.Type.Fee do
  @moduledoc """
  Implementation of Transaction behaviour for Fee claiming type.
  """

  @behaviour ExPlasma.Transaction

  import ABI.TypeEncoder, only: [encode_raw: 2]

  alias __MODULE__.Validator
  alias ExPlasma.Crypto
  alias ExPlasma.Output
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.TypeMapper

  @tx_type TypeMapper.tx_type_for(:tx_fee_token_claim)
  @output_type TypeMapper.output_type_for(:output_fee_token_claim)

  @type validation_error() :: Validator.outputs_validation_error() | {:nonce, :malformed_nonce}
  @type mapping_error() :: :malformed_transaction

  @doc """
  Creates output for a fee transaction

  ## Example

  iex> output = new_output(<<1::160>>, <<0::160>>, 1)
  iex> %ExPlasma.Output{
  ...>   output_data: %{amount: 1, output_guard: <<1::160>>, token: <<0::160>>},
  ...>   output_id: nil,
  ...>   output_type: 2
  ...> } = output
  """
  @spec new_output(Crypto.address_t(), Crypto.address_t(), pos_integer()) :: Output.t()
  def new_output(fee_claimer, token, amount) do
    %Output{
      output_type: @output_type,
      output_data: %{
        amount: amount,
        output_guard: fee_claimer,
        token: token
      }
    }
  end

  @impl Transaction
  def build_nonce(%{blknum: blknum, token: token}) do
    blknum_bytes = encode_raw([blknum], [{:uint, 256}])
    token_bytes = encode_raw([token], [:address])

    {:ok, Crypto.keccak_hash(blknum_bytes <> token_bytes)}
  end

  def build_nonce(_), do: {:error, :invalid_nonce_params}

  @doc """
  Turns a structure instance into a structure of RLP items, ready to be RLP encoded, for a raw transaction
  """
  @impl Transaction
  def to_rlp(transaction) do
    [
      <<@tx_type>>,
      Enum.map(transaction.outputs, &Output.to_rlp(&1)),
      transaction.nonce
    ]
  end

  @doc """
  Decodes an RLP list into a Fee Transaction.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @impl Transaction
  def to_map([<<@tx_type>>, outputs_rlp, nonce_rlp]) do
    case decode_outputs(outputs_rlp) do
      {:ok, outputs} ->
        {:ok,
         %Transaction{
           tx_type: @tx_type,
           outputs: outputs,
           nonce: nonce_rlp
         }}

      {:error, _mapping_error_atom} = error ->
        error
    end
  end

  def to_map(_), do: {:error, :malformed_transaction}

  @doc """
  Validates the Transaction.
  """
  @impl Transaction
  def validate(transaction) do
    with :ok <- Validator.validate_outputs(transaction.outputs),
         :ok <- Validator.validate_nonce(transaction.nonce) do
      :ok
    end
  end

  defp decode_outputs(outputs_rlp) do
    {:ok, Enum.map(outputs_rlp, &Output.decode(&1))}
  rescue
    _ -> {:error, :malformed_outputs}
  end
end
