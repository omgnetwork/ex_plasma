defmodule ExPlasma.Transaction.Type.Fee do
  @moduledoc """
  Internal representation of a fee claiming transaction in plasma chain.
  """

  import ABI.TypeEncoder, only: [encode_raw: 2]

  alias ExPlasma.Crypto
  alias ExPlasma.Output
  alias ExPlasma.Transaction.TypeMapper

  @tx_type TypeMapper.tx_type_for(:tx_fee_token_claim)
  @output_type TypeMapper.output_type_for(:output_fee_token_claim)

  defstruct tx_type: @tx_type, outputs: [], nonce: nil

  @type t() :: %__MODULE__{
          tx_type: pos_integer(),
          outputs: [Output.t()],
          nonce: Crypto.hash_t()
        }

  @doc """
  Creates new fee claiming transaction
  """
  @spec new(
          blknum :: non_neg_integer(),
          {Crypto.address_t(), Crypto.address_t(), pos_integer}
        ) :: t()
  def new(blknum, {fee_claimer, token, amount}) do
    %__MODULE__{
      tx_type: @tx_type,
      outputs: [new_output(fee_claimer, token, amount)],
      nonce: build_nonce(blknum, token)
    }
  end

  @doc """
  Creates output for a fee transaction
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

  @spec build_nonce(non_neg_integer(), Crypto.address_t()) :: Crypto.hash_t()
  defp build_nonce(blknum, token) do
    blknum_bytes = encode_raw([blknum], [{:uint, 256}])
    token_bytes = encode_raw([token], [:address])

    Crypto.keccak_hash(blknum_bytes <> token_bytes)
  end
end

defimpl ExPlasma.Transaction.Protocol, for: ExPlasma.Transaction.Type.Fee do
  alias ExPlasma.Output
  alias ExPlasma.Transaction.Type.Fee
  alias ExPlasma.Transaction.TypeMapper

  @tx_type TypeMapper.tx_type_for(:tx_fee_token_claim)
  @output_type TypeMapper.output_type_for(:output_fee_token_claim)

  @type validation_error() ::
          {:output_type, :invalid_output_type_for_transaction}
          | {:outputs, :wrong_number_of_fee_outputs}
          | {:outputs, :fee_output_amount_has_to_be_positive}
          | {:nonce, :malformed_nonce}
          | {atom(), atom()}

  @type mapping_error() :: :malformed_transaction

  @doc """
  Turns a structure instance into a structure of RLP items, ready to be RLP encoded, for a raw transaction
  """
  @spec to_rlp(Fee.t()) :: list()
  def to_rlp(%Fee{} = transaction) do
    %Fee{outputs: outputs, nonce: nonce} = transaction

    [
      <<@tx_type>>,
      Enum.map(outputs, &Output.to_rlp(&1)),
      nonce
    ]
  end

  @doc """
  Decodes an RLP list into a Fee Transaction.

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.
  """
  @spec to_map(Fee.t(), list()) :: {:ok, Fee.t()} | {:error, mapping_error()}
  def to_map(%Fee{}, [<<@tx_type>>, outputs_rlp, nonce_rlp]) do
    {:ok,
     %Fee{
       tx_type: @tx_type,
       outputs: Enum.map(outputs_rlp, &Output.decode(&1)),
       nonce: nonce_rlp
     }}
  end

  def to_map(_, _), do: {:error, :malformed_transaction}

  @spec validate(Fee.t()) :: :ok | {:error, validation_error()}
  def validate(%Fee{} = transaction) do
    with :ok <- validate_outputs(transaction.outputs),
         :ok <- validate_nonce(transaction.nonce) do
      :ok
    end
  end

  defp validate_outputs(outputs) do
    with {:ok, output} <- validate_outputs_count(outputs),
         :ok <- validate_generic_output(output),
         :ok <- validate_output_type(output),
         :ok <- validate_output_amount(output) do
      :ok
    end
  end

  defp validate_generic_output(output) do
    with {:ok, _} <- Output.validate(output), do: :ok
  end

  defp validate_outputs_count([output]), do: {:ok, output}
  defp validate_outputs_count(_outputs), do: {:error, {:outputs, :wrong_number_of_fee_outputs}}

  defp validate_output_type(%Output{output_type: @output_type}), do: :ok
  defp validate_output_type(_output), do: {:error, {:output_type, :invalid_output_type_for_transaction}}

  defp validate_output_amount(%Output{output_data: %{amount: amount}}) when amount > 0, do: :ok
  defp validate_output_amount(_output), do: {:error, {:outputs, :fee_output_amount_has_to_be_positive}}

  defp validate_nonce(nonce) when is_binary(nonce) and byte_size(nonce) == 32, do: :ok
  defp validate_nonce(_nonce), do: {:error, {:nonce, :malformed_nonce}}

  @doc """
  Fee claiming transaction does not contain any inputs.
  """
  @spec get_inputs(Fee.t()) :: list(Output.t())
  def get_inputs(%Fee{}), do: []

  @doc """
  Fee claiming transaction spends single pseudo-output from collected fees.
  """
  @spec get_outputs(Fee.t()) :: list(Output.t())
  def get_outputs(%Fee{} = transaction), do: transaction.outputs

  @spec get_tx_type(Fee.t()) :: pos_integer()
  def get_tx_type(%Fee{} = transaction), do: transaction.tx_type
end
