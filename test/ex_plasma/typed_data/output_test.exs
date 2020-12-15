defmodule ExPlasma.TypedData.OutputTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.TypedData

  describe "encode/2" do
    test "builds an EIP712 encodable output" do
      output = %ExPlasma.Output{
        output_type: 1,
        output_data: %{
          output_guard: <<0::160>>,
          token: <<0::160>>,
          amount: 10
        }
      }

      encoded = TypedData.encode(output, as: :output)

      assert encoded ==
               [
                 "Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)",
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10>>
               ]
    end

    test "builds an EIP712 encodable input" do
      output = %ExPlasma.Output{
        output_id: %{blknum: 1000, txindex: 0, oindex: 0}
      }

      encoded = ExPlasma.TypedData.encode(output, as: :input)

      assert encoded ==
               [
                 "Input(uint256 blknum,uint256 txindex,uint256 oindex)",
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 232>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
                 <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
               ]
    end
  end

  describe "hash/2" do
    test "hashes an eip712 encoded output identifier" do
      output = %ExPlasma.Output{
        output_id: %{blknum: 0, txindex: 0, oindex: 0}
      }

      hashed = ExPlasma.TypedData.hash(output, as: :input)

      assert hashed ==
               <<26, 89, 51, 235, 11, 50, 35, 176, 80, 15, 187, 231, 3, 156, 171, 155, 173, 192, 6, 173, 218, 108, 243,
                 211, 55, 117, 20, 18, 253, 122, 75, 97>>
    end

    test "hashes an eip712 encoded output" do
      output = %ExPlasma.Output{
        output_type: 1,
        output_data: %{
          output_guard: <<0::160>>,
          token: <<0::160>>,
          amount: 10
        }
      }

      hashed = ExPlasma.TypedData.hash(output, as: :output)

      assert hashed ==
               <<215, 8, 60, 19, 55, 10, 155, 112, 243, 199, 49, 150, 131, 140, 14, 12, 157, 118, 195, 214, 198, 94,
                 223, 77, 159, 186, 45, 211, 125, 37, 234, 32>>
    end
  end
end
