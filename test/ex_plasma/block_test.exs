defmodule ExPlasma.BlockTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Block

  alias ExPlasma.Block

  describe "new/1" do
    test "creates a new block" do
      transaction = %ExPlasma.Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        sigs: [],
        tx_data: 0,
        tx_type: 1
      }

      result = Block.new([transaction])

      assert result.transactions == [transaction]
      assert result.hash == ExPlasma.Encoding.merkle_root_hash([ExPlasma.Transaction.encode(transaction)])
    end
  end
end
