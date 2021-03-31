defmodule ExPlasma.TypedData.OutputTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Crypto
  alias ABI.TypeEncoder
  alias ExPlasma.TypedData

  describe "encode/2" do
    test "builds an EIP712 encodable output" do
      type = 1
      output_guard = <<0::160>>
      token = <<0::160>>
      amount = 10

      output = %ExPlasma.Output{
        output_type: type,
        output_data: %{
          output_guard: output_guard,
          token: token,
          amount: amount
        }
      }

      encoded = TypedData.encode(output, as: :output)

      assert encoded ==
               [
                 Crypto.keccak_hash("Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)"),
                 TypeEncoder.encode_raw([type], [{:uint, 256}]),
                 TypeEncoder.encode_raw([output_guard], [{:bytes, 20}]),
                 TypeEncoder.encode_raw([token], [:address]),
                 TypeEncoder.encode_raw([amount], [{:uint, 256}])
               ]
               |> Enum.join()
               |> Crypto.keccak_hash()
    end

    test "builds an EIP712 encodable input" do
      blknum = 1000
      txindex = 0
      oindex = 0

      output = %ExPlasma.Output{
        output_id: %{blknum: blknum, txindex: txindex, oindex: oindex}
      }

      encoded = ExPlasma.TypedData.encode(output, as: :input)

      assert encoded ==
               [
                 Crypto.keccak_hash("Input(uint256 blknum,uint256 txindex,uint256 oindex)"),
                 TypeEncoder.encode_raw([blknum], [{:uint, 256}]),
                 TypeEncoder.encode_raw([txindex], [{:uint, 256}]),
                 TypeEncoder.encode_raw([oindex], [{:uint, 256}])
               ]
               |> Enum.join()
               |> Crypto.keccak_hash()
    end
  end

  # describe "hash/2" do
  #   test "hashes an eip712 encoded output identifier" do
  #     output = %ExPlasma.Output{
  #       output_id: %{blknum: 0, txindex: 0, oindex: 0}
  #     }

  #     hashed = ExPlasma.TypedData.hash(output, as: :input)

  #     assert hashed ==
  #              <<26, 89, 51, 235, 11, 50, 35, 176, 80, 15, 187, 231, 3, 156, 171, 155, 173, 192, 6, 173, 218, 108, 243,
  #                211, 55, 117, 20, 18, 253, 122, 75, 97>>
  #   end

  #   test "hashes an eip712 encoded output" do
  #     output = %ExPlasma.Output{
  #       output_type: 1,
  #       output_data: %{
  #         output_guard: <<0::160>>,
  #         token: <<0::160>>,
  #         amount: 10
  #       }
  #     }

  #     hashed = ExPlasma.TypedData.hash(output, as: :output)

  #     assert hashed ==
  #              <<215, 8, 60, 19, 55, 10, 155, 112, 243, 199, 49, 150, 131, 140, 14, 12, 157, 118, 195, 214, 198, 94,
  #                223, 77, 159, 186, 45, 211, 125, 37, 234, 32>>
  #   end
  # end
end
