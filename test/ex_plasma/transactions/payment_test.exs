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

      assert hd(metadata) == "foo"
      assert length(metadata) == 1
    end

    test "transforms a transaction to a list with sigs" do
      transaction = Transaction.new(%{inputs: [], outputs: [], sigs: ["foo"]})

      [sigs, _inputs, _outputs, metadata] = Transaction.to_list(transaction)

      assert hd(sigs) == "foo"
      assert length(sigs) == 1
      assert length(metadata) == 0
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

    test "encodes transaction with sigs" do
      transaction = Transaction.new(%{inputs: [], outputs: [], sigs: ["foo"]})
      encoded = Transaction.encode(transaction)

      assert encoded ==
               <<232, 196, 131, 102, 111, 111, 208, 195, 128, 128, 128, 195, 128, 128, 128, 195,
                 128, 128, 128, 195, 128, 128, 128, 208, 195, 128, 128, 128, 195, 128, 128, 128,
                 195, 128, 128, 128, 195, 128, 128, 128, 192>>
    end
  end

  describe "decode/1" do
    test "decodes transactions with metadata" do
      transaction = Transaction.new(%{inputs: [], outputs: [], metadata: "foo"})
      encoded = Transaction.encode(transaction)
      decoded = Transaction.decode(encoded)

      assert decoded ==
               %Transaction{
                 tx_hash: nil,
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

    test "decodes transactions with sigs" do
      transaction = Transaction.new(%{inputs: [], outputs: [], sigs: ["foo"]})
      encoded = Transaction.encode(transaction)
      decoded = Transaction.decode(encoded)

      assert decoded ==
               %Transaction{
                 tx_hash: nil,
                 sigs: ["foo"],
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
