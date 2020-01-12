defmodule Conformance.SignaturesTest do
  @moduledoc """
  Conformance tests that check our signing with the plasma contracts.
  """

  use ExUnit.Case, async: false

  alias ExPlasma.Transaction
  alias ExPlasma.Transactions.Payment
  alias ExPlasma.TypedData
  alias ExPlasma.Utxo

  import ExPlasma.Client.Config,
    only: [
      authority_address: 0,
      contract_address: 0
    ]

  @moduletag :conformance

  # The address where eip 712 lib mock is deployed. Ganache keeps this
  # deterministic
  @contract "0xd3aa556287afe63102e5797bfddd2a1e8dbb3ea5"

  test "signs empty transactions",
    do: assert_signs_conform(%Payment{})

  test "signs without inputs",
    do: assert_signs_conform(%Payment{outputs: [%Utxo{owner: authority_address(), currency: <<0::160>>, amount: 1}]})

  test "signs without outputs",
    do: assert_signs_conform(%Payment{inputs: [%Utxo{blknum: 1, txindex: 0, oindex: 0}]})

  test "signs with metadata",
    do: %Transaction{metadata: <<1::160>>}

  test "signs with a minimal transaction (1x1)",
    do:
      assert_signs_conform(%Payment{
        inputs: [%Utxo{blknum: 1, txindex: 0, oindex: 0}],
        outputs: [%Utxo{owner: authority_address(), currency: <<0::160>>, amount: 1}]
      })

  test "signs with a filled transaction (4x4)" do
    inputs = List.duplicate(%Utxo{blknum: 1, txindex: 0, oindex: 0}, 4)
    outputs = List.duplicate(%Utxo{amount: 1, currency: <<0::160>>, owner: authority_address()}, 4)
    assert_signs_conform(%Payment{inputs: inputs, outputs: outputs})
  end

  defp assert_signs_conform(%{} = transaction) do
    tx_bytes = Transaction.encode(transaction)
    typed_data_hash = TypedData.hash(transaction)

    assert typed_data_hash == verify_hash(tx_bytes)
  end

  defp verify_hash(tx_bytes) do
    verifying_address = contract_address() |> ExPlasma.Encoding.to_binary()

    eth_call("hashTx(address,bytes)", [verifying_address, tx_bytes], [to: @contract], fn resp ->
      resp |> decode_response([{:bytes, 32}]) |> hd()
    end)
  end

  defp eth_call(contract_signature, data_types, [to: to], callback) when is_list(data_types) do
    to = to || contract_address()
    options = %{data: encode_data(contract_signature, data_types), to: to}

    case Ethereumex.HttpClient.eth_call(options) do
      {:ok, resp} -> callback.(resp)
      other -> other
    end
  end

  @spec encode_data(String.t(), list()) :: binary
  defp encode_data(function_signature, data) do
    data = ABI.encode(function_signature, data)
    "0x" <> Base.encode16(data, case: :lower)
  end

  @spec decode_response(String.t(), list()) :: list()
  defp decode_response("0x" <> unprefixed_hash_response, types) do
    unprefixed_hash_response
    |> Base.decode16!(case: :lower)
    |> ABI.TypeDecoder.decode_raw(types)
  end
end
