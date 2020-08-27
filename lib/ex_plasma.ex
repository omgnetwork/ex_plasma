defmodule ExPlasma do
  @moduledoc """
  Documentation for ExPlasma.
  """

  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.TypeMapper

  # constants that identify payment types, make sure that
  # when we introduce a new payment type, you name it `paymentV2`
  # https://github.com/omisego/plasma-contracts/blob/6ab35256b805e25cfc30d85f95f0616415220b20/plasma_framework/docs/design/tx-types-dependencies.md
  @payment_v1 TypeMapper.tx_type_for(:tx_payment_v1)
  @fee TypeMapper.tx_type_for(:tx_fee_token_claim)

  @type transaction_type :: non_neg_integer()

  @doc """
  Simple payment type V1

  ## Example

    iex> ExPlasma.payment_v1()
    1
  """
  @spec payment_v1() :: 1
  def payment_v1(), do: @payment_v1

  @doc """
  Transaction fee claim V1

  ## Example

    iex> ExPlasma.fee()
    3
  """
  @spec fee() :: 3
  def fee(), do: @fee

  @doc """
  Transaction types

  ## Example

    iex> ExPlasma.transaction_types()
    [1, 3]
  """
  @spec transaction_types :: [1 | 3, ...]
  def transaction_types(), do: [payment_v1(), fee()]

  @doc """
  Encode the given Transaction into an RLP encodable list.

  If `signed: false` is given in the list of opts, will encode the transaction without its signatures.

  ## Example

    iex> txn =
    ...>  %ExPlasma.Transaction{
    ...>    inputs: [
    ...>      %ExPlasma.Output{
    ...>        output_data: nil,
    ...>        output_id: %{blknum: 0, oindex: 0, position: 0, txindex: 0},
    ...>        output_type: nil
    ...>      }
    ...>    ],
    ...>    metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
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
    ...>    sigs: [],
    ...>    tx_data: 0,
    ...>    tx_type: 1
    ...>  }
    iex> ExPlasma.encode(txn, signed: false)
    {:ok, <<248, 116, 1, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 237, 1, 235, 148, 29, 246, 47,
    41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110,
    148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
    241, 55, 0, 110, 1, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}
  """
  defdelegate encode(transaction, opts \\ []), to: Transaction

  @doc """
  Throwing version of encode/2
  """
  defdelegate encode!(transaction, opts \\ []), to: Transaction

  @doc """
  Attempt to decode the given RLP list into a Transaction.

  If `signed: false` is given in the list of opts, expects the underlying RLP to not contain signatures.

  Only validates that the RLP is structurally correct and that the tx type is supported.
  Does not perform any other kind of validation, use validate/1 for that.

  ## Example

    iex> rlp = <<248, 116, 1, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ...>  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 237, 1, 235, 148,
    ...>  29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
    ...>  55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217,
    ...>  206, 65, 226, 241, 55, 0, 110, 1, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ...>  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    iex> ExPlasma.decode(rlp, signed: false)
    {:ok,
      %ExPlasma.Transaction{
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
        witnesses: [],
        sigs: [],
        tx_data: 0,
        tx_type: 1
      }
    }
  """
  defdelegate decode(tx_bytes, opts \\ []), to: Transaction

  @doc """
  Keccak hash the Transaction. This is used in the contracts and events to to reference transactions.


  ## Example

  iex> rlp = <<248, 74, 192, 1, 193, 128, 239, 174, 237, 1, 235, 148, 29, 246, 47, 41, 27,
  ...> 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46,
  ...> 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
  ...> 0, 110, 1, 128, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ...> 0>>
  iex> ExPlasma.hash(rlp)
  {:ok, <<87, 132, 239, 36, 144, 239, 129, 88, 63, 88, 116, 147, 164, 200, 113, 191,
    124, 14, 55, 131, 119, 96, 112, 13, 28, 178, 251, 49, 16, 127, 58, 96>>}
  """
  defdelegate hash(transaction), to: Transaction

  @doc """
  Statelessly validate a transation.

  Returns :ok if valid or {:error, {atom, atom}} otherwise
  """
  defdelegate validate(transaction), to: Transaction
end
