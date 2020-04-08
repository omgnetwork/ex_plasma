defmodule ExPlasma.Output.PaymentV1 do
  #@moduledoc """
  #Payment V1 Output Type.
  #"""

  #@zero_address <<0::160>>

  #def encode()

  #def decode()

  #@spec validate(ExPlasma.Output.output_data()) :: {:error, {atom(), atom()}} | {:ok, map()}
  #def validate(output_data) do
    #case do_validate() do
      #{field, value} ->
        #{:error, {field, value}}
      #nil ->
        #{:ok, decode(output_data)
    #end
  #end

  #defp do_validate([output_guard, token, nil]), do: {:amount, :cannot_be_nil}
  #defp do_validate([output_guard, token, amount]) when amount <= 0, do: {:amount, :cannot_be_zero}

  #defp do_validate([output_guard, nil, amount]), do: {:token, :cannot_be_nil}
  #defp do_validate([nil, token, amount]), do: {:output_guard, :cannot_be_nil}
  #defp do_validate([@zero_address, token, amount]), do: {:output_guard, :cannot_be_zero}

  #defp do_validate([output_guard, token, amount])
end
