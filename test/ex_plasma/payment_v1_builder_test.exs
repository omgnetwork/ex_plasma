defmodule ExPlasma.PaymentV1BuilderTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.PaymentV1Builder, import: true

  alias ExPlasma.Output
  alias ExPlasma.PaymentV1Builder
  alias ExPlasma.Support.TestEntity
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.Type.PaymentV1

  @alice TestEntity.alice()
  @bob TestEntity.bob()

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
    test "adds input" do
      block_number = 99
      tx_index = 100
      oindex = 101

      assert %{inputs: [output]} =
               PaymentV1Builder.add_input(%PaymentV1{}, blknum: block_number, txindex: tx_index, oindex: oindex)

      assert output.output_id.blknum == block_number
      assert output.output_id.txindex == tx_index
      assert output.output_id.oindex == oindex
    end

    test "appends new input" do
      block_number = 102
      tx_index = 103
      oindex = 104

      transaction = %PaymentV1{
        inputs: [
          %ExPlasma.Output{
            output_data: nil,
            output_id: %{blknum: 99, oindex: 101, txindex: 100},
            output_type: nil
          }
        ],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        tx_data: 0,
        tx_type: 0
      }

      assert %{inputs: [_output, output]} =
               PaymentV1Builder.add_input(transaction, blknum: block_number, txindex: tx_index, oindex: oindex)

      assert output.output_id.blknum == block_number
      assert output.output_id.txindex == tx_index
      assert output.output_id.oindex == oindex
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
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

      tx =
        PaymentV1Builder.new()
        |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> PaymentV1Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
        |> PaymentV1Builder.add_input(blknum: 3, txindex: 0, oindex: 0, position: 3_000_000_000)

      assert {:ok, %Signed{} = signed} = PaymentV1Builder.sign(tx, keys: [key_1, key_1, key_2])
      assert signed.raw_tx == tx
      assert [sig_1, sig_1, sig_2] = signed.sigs
    end
  end

  describe "complete flow" do
    test "builds and sign a payment v1 transaction with both inputs and outputs" do
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

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
                   <<130, 89, 40, 246, 220, 178, 131, 241, 16, 106, 27, 67, 32, 118, 106, 91, 161, 143, 162, 136, 87,
                     57, 17, 98, 208, 210, 218, 181, 15, 6, 163, 2, 26, 127, 8, 14, 150, 44, 116, 72, 46, 90, 255, 243,
                     144, 39, 175, 13, 47, 107, 179, 178, 240, 160, 166, 94, 252, 119, 38, 82, 49, 254, 192, 250, 27>>,
                   <<130, 89, 40, 246, 220, 178, 131, 241, 16, 106, 27, 67, 32, 118, 106, 91, 161, 143, 162, 136, 87,
                     57, 17, 98, 208, 210, 218, 181, 15, 6, 163, 2, 26, 127, 8, 14, 150, 44, 116, 72, 46, 90, 255, 243,
                     144, 39, 175, 13, 47, 107, 179, 178, 240, 160, 166, 94, 252, 119, 38, 82, 49, 254, 192, 250, 27>>,
                   <<50, 96, 3, 234, 168, 162, 52, 142, 174, 145, 201, 159, 24, 143, 251, 111, 1, 26, 48, 243, 140, 215,
                     21, 137, 161, 128, 184, 139, 183, 28, 161, 146, 22, 132, 29, 228, 34, 241, 196, 53, 155, 142, 69,
                     183, 16, 105, 65, 14, 185, 194, 147, 143, 146, 218, 206, 63, 233, 66, 151, 171, 32, 212, 234, 25,
                     28>>
                 ]
               }
    end
  end
end
