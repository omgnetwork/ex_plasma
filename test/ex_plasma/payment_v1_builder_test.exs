defmodule ExPlasma.PaymentV1BuilderTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.PaymentV1Builder, import: true

  alias ExPlasma.Output
  alias ExPlasma.PaymentV1Builder
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.Type.PaymentV1

  describe "new/1" do
    test "returns a payment v1 struct with given params" do
      input = %Output{output_id: %{blknum: 1, txindex: 0, oindex: 0}}
      output_1 = PaymentV1.new_output(<<1::160>>, <<0::160>>, 1)
      output_2 = PaymentV1.new_output(<<2::160>>, <<0::160>>, 2)
      metadata = <<1::256>>

      tx = PaymentV1Builder.new(metadata: <<1::256>>, inputs: [input], outputs: [output_1, output_2])

      assert tx == %PaymentV1{
               inputs: [input],
               metadata: metadata,
               outputs: [output_1, output_2],
               tx_data: 0
             }
    end

    test "returns an empty payment v1 struct when no param given" do
      tx = PaymentV1Builder.new()

      assert tx == %PaymentV1{
               inputs: [],
               metadata: <<0::256>>,
               outputs: [],
               tx_data: 0
             }
    end
  end

  describe "add_input/2" do
    test "adds the given input to the existing transaction" do
      tx = PaymentV1Builder.new()

      assert tx.inputs == []

      updated_tx = PaymentV1Builder.add_input(tx, blknum: 1, txindex: 0, oindex: 0)

      assert updated_tx.inputs == [
               %Output{output_data: nil, output_id: %{blknum: 1, oindex: 0, txindex: 0}, output_type: nil}
             ]
    end
  end

  describe "add_output/2" do
    test "adds the given output when given `output_data` map to the existing transaction" do
      tx = PaymentV1Builder.new()

      assert tx.outputs == []

      updated_tx =
        PaymentV1Builder.add_output(tx, output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1})

      assert updated_tx.outputs == [
               %Output{output_type: 1, output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}}
             ]
    end

    test "adds the given output when given output data to the existing transaction" do
      tx = PaymentV1Builder.new()

      assert tx.outputs == []

      updated_tx = PaymentV1Builder.add_output(tx, output_guard: <<1::160>>, token: <<0::160>>, amount: 2)

      assert updated_tx.outputs == [
               %Output{output_type: 1, output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 2}}
             ]
    end
  end

  describe "sign/2" do
    test "returns {:ok, signed} when given valid keys" do
      key_1 = "0x0C79EF4FEEA6232854ABFE4006161FC517F4071E5384DBDEF72718B4A4AF016E"
      key_2 = "0x33B41524C9E74DE1F440107E05EEE78754F92F237D23A2655E0370B99EB86568"

      input_1 = %Output{output_id: %{blknum: 1, txindex: 0, oindex: 0}}
      input_2 = %Output{output_id: %{blknum: 3, txindex: 0, oindex: 1}}

      tx = PaymentV1Builder.new(inputs: [input_1, input_2])

      assert {:ok, %Signed{} = signed} = PaymentV1Builder.sign(tx, keys: [key_1, key_2])
      assert signed.raw_tx == tx

      assert signed.sigs == [
               <<171, 176, 24, 83, 58, 83, 237, 134, 126, 22, 76, 122, 112, 110, 87, 221, 116, 79, 32, 73, 153, 195,
                 133, 156, 85, 9, 197, 204, 76, 63, 201, 185, 39, 165, 208, 158, 81, 112, 70, 44, 191, 75, 70, 5, 175,
                 208, 153, 9, 76, 158, 117, 11, 3, 233, 117, 77, 101, 77, 142, 127, 83, 98, 155, 7, 27>>,
               <<211, 0, 125, 100, 221, 58, 14, 178, 84, 220, 97, 236, 3, 90, 95, 165, 186, 166, 106, 173, 207, 82, 146,
                 84, 30, 5, 98, 18, 15, 244, 62, 24, 43, 122, 160, 203, 214, 172, 69, 62, 58, 33, 227, 54, 184, 51, 92,
                 80, 116, 222, 129, 87, 125, 220, 64, 84, 242, 229, 58, 156, 205, 73, 134, 191, 28>>
             ]
    end
  end

  describe "complete flow" do
    test "builds and sign a payment v1 transaction with both inputs and outputs" do
      key_1 = "0x0C79EF4FEEA6232854ABFE4006161FC517F4071E5384DBDEF72718B4A4AF016E"
      key_2 = "0x33B41524C9E74DE1F440107E05EEE78754F92F237D23A2655E0370B99EB86568"

      assert {:ok, txn} =
               [metadata: <<1::160>>, tx_data: 0]
               |> PaymentV1Builder.new()
               |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0)
               |> PaymentV1Builder.add_input(blknum: 2, txindex: 1, oindex: 0)
               |> PaymentV1Builder.add_input(blknum: 3, txindex: 0, oindex: 1)
               |> PaymentV1Builder.add_output(output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1})
               |> PaymentV1Builder.add_output(output_guard: <<1::160>>, token: <<0::160>>, amount: 1)
               |> PaymentV1Builder.add_output(output_guard: <<2::160>>, token: <<0::160>>, amount: 2)
               |> PaymentV1Builder.sign(keys: [key_1, key_1, key_2])

      assert txn ==
               %Signed{
                 raw_tx: %PaymentV1{
                   inputs: [
                     %Output{
                       output_data: nil,
                       output_id: %{blknum: 1, oindex: 0, txindex: 0},
                       output_type: nil
                     },
                     %Output{
                       output_data: nil,
                       output_id: %{blknum: 2, oindex: 0, txindex: 1},
                       output_type: nil
                     },
                     %Output{
                       output_data: nil,
                       output_id: %{blknum: 3, oindex: 1, txindex: 0},
                       output_type: nil
                     }
                   ],
                   metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
                   outputs: [
                     %Output{
                       output_data: %{
                         amount: 1,
                         output_guard: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
                         token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
                       },
                       output_id: nil,
                       output_type: 1
                     },
                     %Output{
                       output_data: %{
                         amount: 1,
                         output_guard: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
                         token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
                       },
                       output_id: nil,
                       output_type: 1
                     },
                     %Output{
                       output_data: %{
                         amount: 2,
                         output_guard: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2>>,
                         token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
                       },
                       output_id: nil,
                       output_type: 1
                     }
                   ],
                   tx_data: 0
                 },
                 sigs: [
                   <<85, 167, 24, 222, 181, 34, 74, 85, 187, 76, 156, 122, 195, 0, 129, 2, 226, 28, 41, 219, 210, 9,
                     211, 210, 182, 224, 41, 222, 115, 116, 122, 184, 115, 147, 22, 194, 191, 8, 197, 160, 225, 8, 167,
                     41, 150, 77, 94, 79, 124, 101, 33, 123, 33, 46, 254, 86, 151, 43, 239, 13, 247, 1, 121, 101, 27>>,
                   <<85, 167, 24, 222, 181, 34, 74, 85, 187, 76, 156, 122, 195, 0, 129, 2, 226, 28, 41, 219, 210, 9,
                     211, 210, 182, 224, 41, 222, 115, 116, 122, 184, 115, 147, 22, 194, 191, 8, 197, 160, 225, 8, 167,
                     41, 150, 77, 94, 79, 124, 101, 33, 123, 33, 46, 254, 86, 151, 43, 239, 13, 247, 1, 121, 101, 27>>,
                   <<188, 170, 182, 152, 81, 117, 180, 129, 60, 205, 66, 67, 188, 8, 63, 75, 230, 62, 129, 251, 64, 167,
                     207, 15, 101, 154, 0, 126, 229, 193, 212, 233, 109, 169, 96, 182, 246, 121, 138, 145, 157, 26, 188,
                     150, 84, 81, 243, 196, 98, 114, 86, 160, 88, 81, 2, 215, 104, 104, 164, 42, 246, 21, 223, 157, 27>>
                 ]
               }
    end
  end
end
