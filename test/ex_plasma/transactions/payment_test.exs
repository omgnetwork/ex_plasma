defmodule ExPlasma.Transaction.PaymentTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction.Payment

  alias ExPlasma.Transaction
  alias ExPlasma.Utxo
  alias ExPlasma.Transaction.Payment

  test "to_rlp/1 forms an RLP-encodable list for a payment transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    input = %Utxo{blknum: 0, txindex: 0, oindex: 0}
    output = %Utxo{owner: owner, currency: currency, amount: 1}
    txn = Payment.new(%{inputs: [input], outputs: [output]})
    list = Transaction.to_rlp(txn)

    assert list == [
             1,
             [
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>
             ],
             [
               [
                 <<1>>,
                 [
                   <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226,
                     241, 55, 0, 110>>,
                   <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
                     55, 0, 110>>,
                   <<1>>
                 ]
               ]
             ],
             0,
             <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0>>
           ]
  end

  test "encode/1 RLP encodes a payment transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    input = %Utxo{blknum: 0, txindex: 0, oindex: 0}
    output = %Utxo{owner: owner, currency: currency, amount: 1}
    txn = Payment.new(%{inputs: [input], outputs: [output]})
    encoded = Transaction.encode(txn)

    assert encoded ==
             <<248, 116, 1, 225, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 237, 1, 235, 148, 29, 246, 47, 41, 27, 46,
               150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45,
               41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 1,
               128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0>>
  end
end
