defmodule ExPlasma.Transaction.TypeMapper do
  @moduledoc """
  Provides wire format's tx/output type values and mapping to modules which decodes them.
  """

  alias ExPlasma.Output
  alias ExPlasma.Transaction

  @type tx_type_to_tx_module_map() :: %{1 => Transaction.Type.PaymentV1, 3 => Transaction.Type.Fee}
  @type tx_type_to_output_module_map() :: %{
          0 => Output.Type.PaymentV1,
          1 => Output.Type.PaymentV1,
          2 => Output.Type.Fee
        }

  @tx_type_values %{
    tx_payment_v1: 1,
    tx_fee_token_claim: 3
  }

  @tx_type_modules %{
    1 => Transaction.Type.PaymentV1,
    3 => Transaction.Type.Fee
  }

  @output_type_values %{
    abstract_payment: 0,
    output_payment_v1: 1,
    output_fee_token_claim: 2
  }

  @output_type_modules %{
    # NB: work-around the TypeData using a "zeroed-out" output to hash the eip712 struct with.
    0 => Output.Type.PaymentV1,
    1 => Output.Type.PaymentV1,
    2 => Output.Type.Fee
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
  @spec tx_type_modules() :: tx_type_to_tx_module_map()
  def tx_type_modules(), do: @tx_type_modules

  @doc """
  Returns wire format type value of known output type
  """
  @spec output_type_for(output_type :: atom()) :: non_neg_integer()
  def output_type_for(output_type) when output_type in @known_output_types, do: @output_type_values[output_type]

  @doc """
  Returns module atom that is able to decode output of given type
  """
  @spec output_type_modules() :: tx_type_to_output_module_map()
  def output_type_modules(), do: @output_type_modules
end
