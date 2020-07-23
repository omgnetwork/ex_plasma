defmodule ExPlasma do
  @moduledoc """
  Documentation for ExPlasma.
  """

  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.TypeMapper

  # constants that identify payment types, make sure that
  # when we introduce a new payment type, you name it `paymentV2`
  # https://github.com/omisego/plasma-contracts/blob/6ab35256b805e25cfc30d85f95f0616415220b20/plasma_framework/docs/design/tx-types-dependencies.md
  @payment_v1 <<TypeMapper.tx_type_for(:tx_payment_v1)>>
  @fee <<TypeMapper.tx_type_for(:tx_fee_token_claim)>>

  @type transaction_type :: <<_::8>>

  @doc """
    Simple payment type V1
  """
  @spec payment_v1() :: transaction_type()
  def payment_v1(), do: @payment_v1

  @doc """
    Transaction fee claim V1
  """
  @spec fee() :: transaction_type()
  def fee(), do: @fee

  @spec transaction_types :: [<<_::8>>, ...]
  def transaction_types(), do: [payment_v1(), fee()]

  @doc """
  Produces a RLP encoded transaction bytes for the given transaction data.

  ## Example

    iex> txn =
    ...>  %ExPlasma.Transaction.Type.PaymentV1{
    ...>    inputs: [
    ...>      %ExPlasma.Output{
    ...>        output_data: nil,
    ...>        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
    ...>        output_type: nil
    ...>      }
    ...>    ],
    ...>    metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    ...>    outputs: [
    ...>      %ExPlasma.Output{
    ...>        output_data: %{
    ...>          amount: 1,
    ...>          output_guard: <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153,
    ...>            217, 206, 65, 226, 241, 55, 0, 110>>,
    ...>          token: <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206,
    ...>            65, 226, 241, 55, 0, 110>>
    ...>        },
    ...>        output_id: nil,
    ...>        output_type: 1
    ...>      }
    ...>    ],
    ...>    tx_data: 0,
    ...>    tx_type: 1
    ...>  }
    iex> ExPlasma.encode(txn)
    <<248, 104, 1, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 237, 1, 235, 148, 29, 246, 47,
    41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110,
    148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
    241, 55, 0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0>>
  """
  defdelegate encode(transaction), to: Transaction

  @doc """
  Decode the given RLP list into a Transaction.

  ## Example

  iex> rlp = <<248, 116, 1, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...>  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 237, 1, 235, 148, 29, 246, 47,
  ...>  41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110,
  ...>  148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
  ...>  241, 55, 0, 110, 1, 0, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...>  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  iex> ExPlasma.decode(rlp, :raw)
  {:ok,
    %ExPlasma.Transaction.Type.PaymentV1{
      inputs: [
        %ExPlasma.Output{
          output_data: nil,
          output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
          output_type: nil
        }
      ],
      metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
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
      tx_data: 0,
      tx_type: 1
    }
  }
  """
  defdelegate decode(tx_bytes, mode), to: Transaction

  @doc """
  Keccak hash the Transaction. This is used in the contracts and events to to reference transactions.


  ## Example

  iex> rlp = <<248, 74, 192, 1, 193, 128, 239, 174, 237, 1, 235, 148, 29, 246, 47, 41, 27,
  ...> 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46,
  ...> 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
  ...> 0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...> 0>>
  iex> ExPlasma.hash(rlp)
  <<87, 132, 239, 36, 144, 239, 129, 88, 63, 88, 116, 147, 164, 200, 113, 191,
    124, 14, 55, 131, 119, 96, 112, 13, 28, 178, 251, 49, 16, 127, 58, 96>>
  """
  defdelegate hash(transaction), to: Transaction
end
