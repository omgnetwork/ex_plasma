defmodule ExPlasma.Output.Type.PaymentV1 do
  @moduledoc """
  Payment V1 Output Type.
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

  @output_type 1
  @zero_address <<0::160>>

  @doc """
  Encode a map of the output data into an RLP list.

  ## Example

  iex> output = %{output_guard: <<1::160>>, token: <<1::160>>, amount: <<1>>}
  iex> ExPlasma.Output.Type.PaymentV1.to_rlp(output)
  [<<1>>, [<<1::160>>, <<1::160>>, <<1>>]]
  """
  @impl Output
  @spec to_rlp(t()) :: rlp()
  def to_rlp(%{output_guard: output_guard, token: token, amount: amount}) do
    [
      <<@output_type>>, 
      [
        output_guard,
        token,
        truncate_leading_zero(amount)
      ]
    ]
  end

  @doc """
  Decode a map of the output data into the Payment V1 format:

  ## Example
  iex> data = [<<1::160>>, <<1::160>>, <<1>>]
  iex> ExPlasma.Output.Type.PaymentV1.to_map(data)
  %{output_guard: <<1::160>>, token: <<1::160>>, amount: <<1>>}
  """
  @impl Output
  @spec to_map(rlp()) :: t()
  def to_map([output_guard, token, amount]) do
    %{output_guard: output_guard, token: token, amount: amount}
  end

  @doc """
  Validates the output data

  ## Example
  iex> data = %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
  iex> {:ok, resp} = ExPlasma.Output.Type.PaymentV1.validate(data)
  {:ok, %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}}
  """
  @impl Output
  @spec validate(t()) :: validation_responses()
  def validate(%{output_guard: output_guard, token: token, amount: amount} = data) do
    case do_validate([output_guard, token, amount]) do
      {field, value} ->
        {:error, {field, value}}
      nil ->
        {:ok, data}
    end
  end

  defp do_validate([_output_guard, _token, nil]), do: {:amount, :cannot_be_nil}
  defp do_validate([_output_guard, _token, amount]) when amount <= 0, do: {:amount, :cannot_be_zero}

  defp do_validate([_output_guard, nil, _amount]), do: {:token, :cannot_be_nil}
  defp do_validate([nil, _token, _amount]), do: {:output_guard, :cannot_be_nil}
  defp do_validate([@zero_address, _token, _amount]), do: {:output_guard, :cannot_be_zero}

  defp do_validate([_, _, _]), do: nil

  defp truncate_leading_zero(<<0>>), do: <<0>>
  defp truncate_leading_zero(<<0>> <> binary), do: truncate_leading_zero(binary)
  defp truncate_leading_zero(binary), do: binary
end
