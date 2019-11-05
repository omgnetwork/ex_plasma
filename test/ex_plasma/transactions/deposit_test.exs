defmodule ExPlasma.Transactions.DepositTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transactions.Deposit

  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Input
  alias ExPlasma.Transaction.Output
  alias ExPlasma.Transactions.Deposit

  describe "new/1" do
    test "does not allow more than 0 input" do
      inputs = [%Input{}]
      outputs = [%Output{}]

      assert_raise FunctionClauseError, fn ->
        Deposit.new(inputs: inputs, outputs: outputs, metadata: nil)
      end
    end

    test "does not allow more than 1 output" do
      outputs = List.duplicate(%Output{}, 2)

      assert_raise FunctionClauseError, fn ->
        Deposit.new(inputs: [], outputs: outputs, metadata: nil)
      end
    end
  end

  test "to_list/1 forms an RLP-encodable list for a deposit transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    amount = 1
    metadata = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    transaction = Deposit.new(owner, currency, amount, metadata)
    list = Transaction.to_list(transaction)

    assert list == [
             1,
             [],
             [
               [
                 1,
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

  test "encode/1 RLP encodes a deposit transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
    amount = 1
    metadata = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    transaction = Deposit.new(owner, currency, amount, metadata)
    rlp_encoded = Transaction.encode(transaction)

    assert rlp_encoded ==
             <<248, 69, 1, 192, 237, 236, 1, 148, 29, 246, 47, 41, 27, 46, 150, 159, 176, 132,
               157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45, 41, 28, 46, 150,
               159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 1, 148, 29, 246, 47,
               41, 27, 46, 150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110>>
  end
end
