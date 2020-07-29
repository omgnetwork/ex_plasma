defmodule ExPlasma.Output.Type.GenericPayment do
  @moduledoc """
  Generic payment output type.
  """

  @behaviour ExPlasma.Output

  alias ExPlasma.Output

  @type address() :: <<_::160>>
  @type output_guard() :: address()
  @type token() :: address()
  @type amount() :: non_neg_integer()

  @type rlp() :: [output_guard() | [token() | amount()]]

  @type validation_responses() :: {:ok, t()}

  @type t() :: %{
          output_guard: output_guard(),
          token: token(),
          amount: amount()
        }

  @zero_address <<0::160>>

  @doc """
  Encode a map of the output data into an RLP list.

  ## Example

  iex> output = %{output_type: 1, output_data: %{output_guard: <<1::160>>, token: <<1::160>>, amount: 1}}
  iex> ExPlasma.Output.Type.GenericPayment.to_rlp(output)
  [<<1>>, [<<1::160>>, <<1::160>>, <<1>>]]
  """
  @impl Output
  @spec to_rlp(Output.t()) :: rlp()
  def to_rlp(%{output_type: type, output_data: data}) do
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
  Decode a map of the output data into the Payment V1 format:

  ## Example
  iex> data = [<<1>>, [<<1::160>>, <<1::160>>, <<1>>]]
  iex> ExPlasma.Output.Type.GenericPayment.to_map(data)
  %{
    output_type: 1,
    output_data: %{output_guard: <<1::160>>, token: <<1::160>>, amount: 1}
  }
  """
  @impl Output
  @spec to_map([<<_::8>> | [any(), ...], ...]) :: %{
          :output_data => %{:amount => non_neg_integer(), :output_guard => any(), :token => any()},
          :output_type => byte()
        }
  def to_map([<<output_type>>, [output_guard, token, amount]]) do
    %{
      output_type: output_type,
      output_data: %{output_guard: output_guard, token: token, amount: :binary.decode_unsigned(amount, :big)}
    }
  end

  @doc """
  Validates the output data

  ## Example
  iex> data = %{output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}}
  iex> {:ok, resp} = ExPlasma.Output.Type.GenericPayment.validate(data)
  {:ok, %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}}
  """
  @impl Output
  @spec validate(Output.t()) :: validation_responses()
  def validate(%{output_data: data}) do
    case do_validate([data.output_guard, data.token, data.amount]) do
      {field, value} ->
        {:error, {field, value}}

      :ok ->
        {:ok, data}
    end
  end

  defp do_validate([_output_guard, _token, nil]), do: {:amount, :cannot_be_nil}

  defp do_validate([_output_guard, _token, amount]) when amount <= 0,
    do: {:amount, :cannot_be_zero}

  defp do_validate([_output_guard, nil, _amount]), do: {:token, :cannot_be_nil}
  defp do_validate([nil, _token, _amount]), do: {:output_guard, :cannot_be_nil}
  defp do_validate([@zero_address, _token, _amount]), do: {:output_guard, :cannot_be_zero}
  defp do_validate([<<_::160>>, _token, _amount]), do: :ok

  defp do_validate([_, _, _]), do: {:output_guard, :invalid_length}

  defp truncate_leading_zero(<<0>>), do: <<0>>
  defp truncate_leading_zero(<<0>> <> binary), do: truncate_leading_zero(binary)
  defp truncate_leading_zero(binary), do: binary
end
