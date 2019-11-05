defmodule ExPlasma.Transactions.PaymentTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transactions.Payment

  alias ExPlasma.Transactions.Payment, as: Transaction

  describe "new/3" do
    test "does not build Transaction with too many inputs" do
      inputs = List.duplicate(%{blknum: 0, txindex: 0, oindex: 0}, 10)

      assert_raise FunctionClauseError, fn ->
        Transaction.new(%{inputs: inputs, outputs: [], metadata: "foo"})
      end
    end

    test "does not build Transaction with too many outputs" do
      outputs = List.duplicate(%{owner: 0, currency: 0, amount: 0}, 10)

      assert_raise FunctionClauseError, fn ->
        Transaction.new(%{inputs: [], outputs: outputs, metadata: "foo"})
      end
    end
  end

  describe "to_list/1" do
    test "transforms a transaction to a list with metadata" do
      transaction = Transaction.new(%{inputs: [], outputs: [], metadata: "foo"})

      [_inputs, _outputs, metadata] = Transaction.to_list(transaction)

      assert metadata == "foo"
    end
  end

  describe "encode/1" do
    test "encodes transactions with metadata" do
      transaction = Transaction.new(%{inputs: [], outputs: [], metadata: "foo"})
      encoded = Transaction.encode(transaction)

      assert encoded ==
               <<231, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128,
                 128, 128, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195, 128, 128, 128, 195,
                 128, 128, 128, 196, 131, 102, 111, 111>>
    end
  end

  describe "decode/1" do
    test "decodes transactions with metadata" do
      transaction = Transaction.new(%{inputs: [], outputs: [], metadata: "foo"})
      encoded = Transaction.encode(transaction)
      decoded = Transaction.decode(encoded)

      assert decoded ==
               %Transaction{
                 metadata: "foo",
                 inputs: [
                   %{blknum: 0, oindex: 0, txindex: 0},
                   %{blknum: 0, oindex: 0, txindex: 0},
                   %{blknum: 0, oindex: 0, txindex: 0},
                   %{blknum: 0, oindex: 0, txindex: 0}
                 ],
                 outputs: [
                   %{amount: 0, currency: 0, owner: 0},
                   %{amount: 0, currency: 0, owner: 0},
                   %{amount: 0, currency: 0, owner: 0},
                   %{amount: 0, currency: 0, owner: 0}
                 ]
               }
    end
  end
end
