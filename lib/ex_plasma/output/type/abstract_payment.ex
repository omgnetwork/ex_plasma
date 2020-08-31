defmodule ExPlasma.Output.Type.AbstractPayment do
  @moduledoc """
  Abstract payment output type.
  """

  @behaviour ExPlasma.Output

  alias __MODULE__.Validator
  alias ExPlasma.Output
  alias ExPlasma.Utils.RlpDecoder

  @type address() :: <<_::160>>
  @type output_guard() :: address()
  @type token() :: address()
  @type amount() :: non_neg_integer()
  @type mapping_errors() ::
          :malformed_output_guard
          | :malformed_output_token
          | :malformed_output_amount

  @type rlp() :: [<<_::8>> | [output_guard() | [token() | binary()]]]

  @type validation_responses() :: {:ok, t()}

  @type t() :: %{
          output_guard: output_guard(),
          token: token(),
          amount: amount()
        }

  @type validation_error() ::
          Validator.amount_validation_errors()
          | Validator.token_validation_errors()
          | Validator.output_guard_validation_errors()

  @doc """
  Encode a map of the output data into an RLP list.

  ## Example

  iex> output = %{output_type: 1, output_data: %{output_guard: <<1::160>>, token: <<1::160>>, amount: 1}}
  iex> ExPlasma.Output.Type.AbstractPayment.to_rlp(output)
  [<<1>>, [<<1::160>>, <<1::160>>, <<1>>]]
  """
  @impl Output
  @spec to_rlp(Output.t()) :: rlp()
  def to_rlp(output) do
    %{output_type: type, output_data: data} = output

    [
      <<type>>,
      [
        data.output_guard,
        data.token,
        truncate_leading_zero(<<data.amount::integer-size(256)>>)
      ]
    ]
  end

  @doc """
  Decode a map of the output data into the Abstract Payment format

  Only validates that the RLP is structurally correct.
  Does not perform any other kind of validation, use validate/1 for that.

  ## Example
  iex> data = [<<1>>, [<<1::160>>, <<1::160>>, <<1>>]]
  iex> ExPlasma.Output.Type.AbstractPayment.to_map(data)
  {:ok, %{
    output_type: 1,
    output_data: %{output_guard: <<1::160>>, token: <<1::160>>, amount: 1}
  }}
  """
  @impl Output
  @spec to_map(rlp()) :: {:ok, %{output_data: t(), output_type: non_neg_integer()}} | {:error, mapping_errors()}
  def to_map([<<output_type>>, [output_guard_rlp, token_rlp, amount_rlp]]) do
    with {:ok, output_guard} <- decode_output_guard(output_guard_rlp),
         {:ok, token} <- decode_token(token_rlp),
         {:ok, amount} <- decode_amount(amount_rlp) do
      {:ok,
       %{
         output_type: output_type,
         output_data: %{output_guard: output_guard, token: token, amount: amount}
       }}
    end
  end

  def to_map(_), do: {:error, :malformed_outputs}

  @doc """
  Validates the output data

  ## Example
  iex> data = %{output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}}
  iex> ExPlasma.Output.Type.AbstractPayment.validate(data)
  :ok
  """
  @impl Output
  def validate(output) do
    with :ok <- Validator.validate_amount(output.output_data.amount),
         :ok <- Validator.validate_token(output.output_data.token),
         :ok <- Validator.validate_output_guard(output.output_data.output_guard) do
      :ok
    end
  end

  defp truncate_leading_zero(<<0>>), do: <<0>>
  defp truncate_leading_zero(<<0>> <> binary), do: truncate_leading_zero(binary)
  defp truncate_leading_zero(binary), do: binary

  defp decode_output_guard(output_guard_rlp) do
    case RlpDecoder.parse_address(output_guard_rlp) do
      {:ok, output_guard} -> {:ok, output_guard}
      _error -> {:error, :malformed_output_guard}
    end
  end

  defp decode_token(token_rlp) do
    case RlpDecoder.parse_address(token_rlp) do
      {:ok, token} -> {:ok, token}
      _error -> {:error, :malformed_output_token}
    end
  end

  defp decode_amount(amount_rlp) do
    case RlpDecoder.parse_uint256(amount_rlp) do
      {:ok, amount} -> {:ok, amount}
      _error -> {:error, :malformed_output_amount}
    end
  end
end
