defmodule ExPlasma.Transaction.TypeMapper do
  @moduledoc """
  Provides wire format's tx/output type values and mapping to modules which decodes them.
  """

  @type tx_type_to_module_map() :: %{non_neg_integer() => atom()}

  @tx_type_values %{
    tx_payment_v1: 1,
    tx_fee_token_claim: 3
  }

  @tx_type_modules %{
    1 => ExPlasma.Transaction.Type.PaymentV1,
    3 => ExPlasma.Transaction.Type.Fee
  }

  @module_tx_types %{
    ExPlasma.Transaction.Type.PaymentV1 => 1,
    ExPlasma.Transaction.Type.Fee => 3
  }

  @output_type_values %{
    output_payment_v1: 1,
    output_fee_token_claim: 2
  }

  @output_type_modules %{
    1 => ExPlasma.Output,
    2 => ExPlasma.Output
  }

  @known_tx_types Map.keys(@tx_type_values)
  @known_output_types Map.keys(@output_type_values)

  @doc """
  Returns wire format type value of known transaction type
  """
  @spec tx_type_for(tx_type :: atom()) :: non_neg_integer()
  def tx_type_for(tx_type) when tx_type in @known_tx_types, do: @tx_type_values[tx_type]

  @doc """
  Returns module atom that is able to decode transaction of given type
  """
  @spec tx_type_modules() :: tx_type_to_module_map()
  def tx_type_modules(), do: @tx_type_modules

  @doc """
  Returns the tx type that is associated with the given module
  """
  @spec module_tx_types() :: %{atom() => non_neg_integer()}
  def module_tx_types(), do: @module_tx_types

  @doc """
  Returns wire format type value of known output type
  """
  @spec output_type_for(output_type :: atom()) :: non_neg_integer()
  def output_type_for(output_type) when output_type in @known_output_types, do: @output_type_values[output_type]

  @doc """
  Returns module atom that is able to decode output of given type
  """
  @spec output_type_modules() :: tx_type_to_module_map()
  def output_type_modules(), do: @output_type_modules
end
