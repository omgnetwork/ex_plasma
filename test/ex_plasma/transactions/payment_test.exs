defmodule ExPlasma.Transactions.PaymentTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transactions.Payment

  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Input
  alias ExPlasma.Transaction.Output
  alias ExPlasma.Transactions.Payment

  test "to_list/1 forms an RLP-encodable list for a payment transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    amount = 1
    metadata = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    output = %Output{owner: owner, currency: currency, amount: amount}
    input = %Input{}
    transaction = Payment.new(inputs: [input], outputs: [output], metadata: metadata)
    list = Transaction.to_list(transaction)

    assert list == [
             <<1>>,
             [[0, 0, 0]],
             [
               [
                 <<1>>,
                 <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
                   55, 0, 110>>,
                 <<46, 38, 45, 41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
                   55, 0, 110>>,
                 1
               ]
             ],
             <<29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55,
               0, 110>>
           ]
  end

  test "encode/1 RLP encodes a payment transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    amount = 1
    metadata = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    output = %Output{owner: owner, currency: currency, amount: amount}
    input = %Input{}
    transaction = Payment.new(inputs: [input], outputs: [output], metadata: metadata)
    rlp_encoded = Transaction.encode(transaction)

    assert rlp_encoded ==
             <<248, 73, 1, 196, 195, 128, 128, 128, 237, 236, 1, 148, 29, 246, 47, 41, 27, 46,
               150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45,
               41, 28, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 1,
               148, 29, 246, 47, 41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241,
               55, 0, 110>>
  end
end
