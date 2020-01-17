defmodule ExPlasma.Transaction.DepositTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction.Deposit

  alias ExPlasma.Transaction
  alias ExPlasma.Utxo
  alias ExPlasma.Transaction.Deposit

  describe "new/1" do
    test "does not allow more than 0 input" do
      assert_raise FunctionClauseError, fn ->
        Deposit.new(%{inputs: [%Utxo{}], outputs: [%Utxo{}]})
      end
    end

    test "does not allow more than 1 output" do
      assert_raise FunctionClauseError, fn ->
        Deposit.new(%{inputs: [], outputs: List.duplicate(%Utxo{}, 2)})
      end
    end
  end

  test "to_rlp/1 forms an RLP-encodable list for a deposit transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"

    {:ok, deposit} = Deposit.new(%Utxo{owner: owner, currency: currency, amount: 1})
    list = Transaction.to_rlp(deposit)

    assert list == [
             1,
             [],
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

  test "encode/1 RLP encodes a deposit transaction" do
    owner = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
    currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"

    {:ok, deposit} = Deposit.new(%Utxo{owner: owner, currency: currency, amount: 1})
    encoded = Transaction.encode(deposit)

    assert encoded ==
             <<248, 83, 1, 192, 238, 237, 1, 235, 148, 29, 246, 47, 41, 27, 46, 150, 159, 176,
               132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 148, 46, 38, 45, 41, 28, 46,
               150, 159, 176, 132, 157, 153, 217, 206, 65, 226, 241, 55, 0, 110, 1, 128, 160, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0>>
  end
end
