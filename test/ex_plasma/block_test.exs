defmodule ExPlasma.BlockTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Block

  alias ExPlasma.Block
  alias ExPlasma.Transaction.Type.PaymentV1

  describe "new/1" do
    test "creates a new block" do
      transaction = %PaymentV1{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        tx_data: 0,
        tx_type: 1
      }

      result = Block.new([transaction])

      assert result.transactions == [transaction]
      assert result.hash == ExPlasma.Merkle.root_hash([ExPlasma.encode(transaction)])
    end
  end
end
