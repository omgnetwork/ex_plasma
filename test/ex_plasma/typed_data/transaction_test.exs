defmodule ExPlasma.TypedData.TransactionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Transaction

  describe "encode/1" do
    test "builds a eip712 transaction object" do
      encoded = ExPlasma.TypedData.encode(%Transaction{tx_type: 1})

      assert encoded == [
               <<25, 1>>,
               [
                 "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)",
                 "OMG Network",
                 "2",
                 "0xd17e1233a03affb9092d5109179b43d6a8828607",
                 "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83"
               ],
               "Transaction(uint256 txType,Input[] inputs,Output[] outputs,uint256 txData,bytes32 metadata)Input(uint256 blknum,uint256 txindex,uint256 oindex)Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)",
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
               [],
               [],
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
             ]
    end
  end

  describe "hash/1" do
    test "hashes a eip 712 encoded object" do
      encoded_hash = ExPlasma.TypedData.hash(%Transaction{tx_type: 1})

      assert encoded_hash ==
               <<196, 145, 245, 73, 70, 135, 10, 204, 85, 216, 199, 89, 153, 191, 31, 94, 60, 22, 20, 81, 54, 74, 38,
                 48, 248, 239, 148, 10, 173, 134, 85, 114>>
    end
  end
end
