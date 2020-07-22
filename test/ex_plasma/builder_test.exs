defmodule ExPlasma.BuilderTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Builder, import: true

  import ExPlasma.Builder

  describe "new/1" do
    test "creates new transaction" do
      inputs = [1, 2]
      outputs = [3, 4]
      sigs = [5, 6]
      tx_type = 1
      tx_data = <<7>>
      metadata = <<8>>

      struct = new(inputs: inputs, outputs: outputs, sigs: sigs, tx_type: tx_type, tx_data: tx_data, metadata: metadata)

      assert struct.inputs == inputs
      assert struct.outputs == outputs
      assert struct.sigs == sigs
      assert struct.tx_type == tx_type
      assert struct.tx_data == tx_data
      assert struct.metadata == metadata
    end
  end

  describe "add_input/2" do
    test "adds input" do
      block_number = 99
      tx_index = 100
      oindex = 101

      assert %{inputs: [output]} =
               add_input(%ExPlasma.Transaction{}, blknum: block_number, txindex: tx_index, oindex: oindex)

      assert output.output_id.blknum == block_number
      assert output.output_id.txindex == tx_index
      assert output.output_id.oindex == oindex
    end

    test "appends new input" do
      block_number = 102
      tx_index = 103
      oindex = 104

      transaction = %ExPlasma.Transaction{
        inputs: [
          %ExPlasma.Output{
            output_data: nil,
            output_id: %{blknum: 99, oindex: 101, txindex: 100},
            output_type: nil
          }
        ],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [],
        sigs: [],
        tx_data: 0,
        tx_type: 0
      }

      assert %{inputs: [_output, output]} =
               add_input(transaction, blknum: block_number, txindex: tx_index, oindex: oindex)

      assert output.output_id.blknum == block_number
      assert output.output_id.txindex == tx_index
      assert output.output_id.oindex == oindex
    end
  end

  describe "add_output/2" do
    test "adds output with custom type" do
      output_data = %{foo: :bar}
      output_type = 100

      assert %{outputs: [output]} =
               add_output(%ExPlasma.Transaction{}, output_type: output_type, output_data: output_data)

      assert output.output_type == output_type
      assert output.output_data == output_data
    end

    test "adds output" do
      assert %{outputs: [output]} = add_output(%ExPlasma.Transaction{}, foo: :bar)

      assert output.output_data == %{foo: :bar}
    end

    test "appends new output" do
      output_data = %{foo1: :bar1}
      output_type = 100

      transaction = %ExPlasma.Transaction{
        inputs: [],
        metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        outputs: [
          %ExPlasma.Output{output_data: %{foo: :bar}, output_id: nil, output_type: 1}
        ],
        sigs: [],
        tx_data: 0,
        tx_type: 0
      }

      assert %{outputs: [_output, output]} = add_output(transaction, output_type: output_type, output_data: output_data)

      assert output.output_type == output_type
      assert output.output_data == output_data
    end
  end

  test "builds and sign a transaction with both inputs and outputs" do
    key_1 = "0x0C79EF4FEEA6232854ABFE4006161FC517F4071E5384DBDEF72718B4A4AF016E"
    key_2 = "0x33B41524C9E74DE1F440107E05EEE78754F92F237D23A2655E0370B99EB86568"

    txn =
      [tx_type: 1, metadata: <<1::160>>, tx_data: 0]
      |> new()
      |> add_input(blknum: 1, txindex: 0, oindex: 0)
      |> add_input(blknum: 2, txindex: 1, oindex: 0)
      |> add_input(blknum: 3, txindex: 0, oindex: 1)
      |> add_output(
        output_type: 1,
        output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
      )
      |> add_output(output_guard: <<1::160>>, token: <<0::160>>, amount: 1)
      |> add_output(output_guard: <<2::160>>, token: <<0::160>>, amount: 2)
      |> sign([key_1, key_1, key_2])

    assert txn == %ExPlasma.Transaction{
             inputs: [
               %ExPlasma.Output{
                 output_data: nil,
                 output_id: %{blknum: 1, oindex: 0, txindex: 0},
                 output_type: nil
               },
               %ExPlasma.Output{
                 output_data: nil,
                 output_id: %{blknum: 2, oindex: 0, txindex: 1},
                 output_type: nil
               },
               %ExPlasma.Output{
                 output_data: nil,
                 output_id: %{blknum: 3, oindex: 1, txindex: 0},
                 output_type: nil
               }
             ],
             metadata: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
             outputs: [
               %ExPlasma.Output{
                 output_data: %{
                   amount: 1,
                   output_guard: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
                   token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
                 },
                 output_id: nil,
                 output_type: 1
               },
               %ExPlasma.Output{
                 output_data: %{
                   amount: 1,
                   output_guard: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
                   token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
                 },
                 output_id: nil,
                 output_type: 1
               },
               %ExPlasma.Output{
                 output_data: %{
                   amount: 2,
                   output_guard: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2>>,
                   token: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
                 },
                 output_id: nil,
                 output_type: 1
               }
             ],
             sigs: [
               <<85, 167, 24, 222, 181, 34, 74, 85, 187, 76, 156, 122, 195, 0, 129, 2, 226, 28, 41, 219, 210, 9, 211,
                 210, 182, 224, 41, 222, 115, 116, 122, 184, 115, 147, 22, 194, 191, 8, 197, 160, 225, 8, 167, 41, 150,
                 77, 94, 79, 124, 101, 33, 123, 33, 46, 254, 86, 151, 43, 239, 13, 247, 1, 121, 101, 27>>,
               <<85, 167, 24, 222, 181, 34, 74, 85, 187, 76, 156, 122, 195, 0, 129, 2, 226, 28, 41, 219, 210, 9, 211,
                 210, 182, 224, 41, 222, 115, 116, 122, 184, 115, 147, 22, 194, 191, 8, 197, 160, 225, 8, 167, 41, 150,
                 77, 94, 79, 124, 101, 33, 123, 33, 46, 254, 86, 151, 43, 239, 13, 247, 1, 121, 101, 27>>,
               <<188, 170, 182, 152, 81, 117, 180, 129, 60, 205, 66, 67, 188, 8, 63, 75, 230, 62, 129, 251, 64, 167,
                 207, 15, 101, 154, 0, 126, 229, 193, 212, 233, 109, 169, 96, 182, 246, 121, 138, 145, 157, 26, 188,
                 150, 84, 81, 243, 196, 98, 114, 86, 160, 88, 81, 2, 215, 104, 104, 164, 42, 246, 21, 223, 157, 27>>
             ],
             tx_data: 0,
             tx_type: 1
           }
  end
end
