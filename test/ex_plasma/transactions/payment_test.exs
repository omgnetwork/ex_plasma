defmodule ExPlasma.Transactions.PaymentTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transactions.Payment

  alias ExPlasma.Transaction
  alias ExPlasma.Utxo
  alias ExPlasma.Transactions.Payment

  test "to_list/1 forms an RLP-encodable list for a payment transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    utxo = %Utxo{owner: owner, currency: currency, amount: 1}
    txn = Payment.new(%{inputs: [utxo], outputs: [utxo]})
    list = Transaction.to_list(txn)

    assert list == [
             <<1>>,
             [
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>
             ],
             [
               [
                 <<1>>,
                 <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
                   55, 0, 110>>,
                 <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
                   55, 0, 110>>,
                 <<0, 0, 0, 0, 0, 0, 0, 1>>
               ]
             ],
             <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0>>
           ]
  end

  test "encode/1 RLP encodes a payment transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    utxo = %Utxo{owner: owner, currency: currency, amount: 1}
    txn = Payment.new(%{inputs: [utxo], outputs: [utxo]})
    encoded = Transaction.encode(txn)

    assert encoded ==
             <<248, 78, 1, 193, 0, 245, 244, 1, 148, 29, 246, 47, 41, 27, 46, 150, 159, 176, 132,
               157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150,
               159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 136, 0, 0, 0, 0, 0, 0,
               0, 1, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  end
end
