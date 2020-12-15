defmodule ExPlasma.Output.Type.AbstractPayment.Validator do
  @moduledoc """
  Contain stateless validation logic for abstract payment outputs
  """

  alias ExPlasma.Crypto

  @zero_address <<0::160>>

  @type amount_validation_errors() :: {:amount, :cannot_be_nil} | {:amount, :cannot_be_zero}
  @type token_validation_errors() :: {:token, :cannot_be_nil}
  @type output_guard_validation_errors() :: {:output_guard, :cannot_be_nil} | {:output_guard, :cannot_be_zero}

  @spec validate_amount(pos_integer()) :: :ok | {:error, amount_validation_errors()}
  def validate_amount(nil), do: {:error, {:amount, :cannot_be_nil}}
  def validate_amount(amount) when amount <= 0, do: {:error, {:amount, :cannot_be_zero}}
  def validate_amount(_amount), do: :ok

  @spec validate_token(Crypto.address_t()) :: :ok | {:error, token_validation_errors()}
  def validate_token(nil), do: {:error, {:token, :cannot_be_nil}}
  def validate_token(_token), do: :ok

  @spec validate_output_guard(Crypto.address_t()) :: :ok | {:error, output_guard_validation_errors()}
  def validate_output_guard(nil), do: {:error, {:output_guard, :cannot_be_nil}}
  def validate_output_guard(@zero_address), do: {:error, {:output_guard, :cannot_be_zero}}
  def validate_output_guard(_output_guard), do: :ok
end
