defmodule ExPlasma.TypedData.TransactionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Transaction2

  describe "encode/1" do
    test "builds a eip712 transaction object" do
      encoded = ExPlasma.TypedData.encode(%Transaction2{})

      assert encoded == [
               <<25, 1>>,
               [
                 "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)",
                 "OMG Network",
                 "1",
                 "0xd17e1233a03affb9092d5109179b43d6a8828607",
                 "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83"
               ],
               "Transaction(uint256 txType,Input input0,Input input1,Input input2,Input input3,Output output0,Output output1,Output output2,Output output3,uint256 txData,bytes32 metadata)Input(uint256 blknum,uint256 txindex,uint256 oindex)Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)",
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>,
               [],
               [],
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>,
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>
             ]
    end
  end

  describe "hash/1" do
    test "hashes a eip 712 encoded object" do
      encoded_hash = ExPlasma.TypedData.hash(%Transaction2{})

      assert encoded_hash ==
               <<237, 222, 56, 55, 149, 76, 223, 131, 240, 226, 246, 122, 166, 114, 38, 102, 122,
                 183, 230, 80, 135, 114, 118, 119, 47, 205, 121, 140, 23, 172, 117, 213>>
    end
  end
end
