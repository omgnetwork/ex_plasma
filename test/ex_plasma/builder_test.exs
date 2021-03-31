defmodule ExPlasma.BuilderTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Builder, import: true

  alias ExPlasma.Builder
  alias ExPlasma.Output
  alias ExPlasma.Support.TestEntity
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Type.PaymentV1

  @alice TestEntity.alice()
  @bob TestEntity.bob()

  describe "new/1" do
    test "returns a transaction representing a payment v1 with given params" do
      input = %Output{output_id: %{blknum: 1, txindex: 0, oindex: 0}}
      output_1 = PaymentV1.new_output(<<1::160>>, <<0::160>>, 1)
      output_2 = PaymentV1.new_output(<<2::160>>, <<0::160>>, 2)
      metadata = <<1::256>>

      tx = Builder.new(ExPlasma.payment_v1(), metadata: <<1::256>>, inputs: [input], outputs: [output_1, output_2])

      assert tx == %Transaction{
               tx_type: 1,
               inputs: [input],
               metadata: metadata,
               outputs: [output_1, output_2],
               tx_data: 0
             }
    end

    test "returns an empty transaction struct of the given type when no param given" do
      tx = Builder.new(ExPlasma.payment_v1())

      assert tx == %Transaction{
               tx_type: 1,
               inputs: [],
               metadata: <<0::256>>,
               outputs: [],
               tx_data: 0
             }
    end
  end

  describe "with_nonce/2" do
    test "returns {:ok, transaction} with a nonce when valid" do
      tx = Builder.new(ExPlasma.fee())

      assert tx.nonce == nil
      assert {:ok, tx_with_nonce} = Builder.with_nonce(tx, %{blknum: 1000, token: <<0::160>>})
      assert %{nonce: nonce} = tx_with_nonce

      assert nonce ==
               <<61, 119, 206, 68, 25, 203, 29, 23, 147, 224, 136, 32, 198, 128, 177, 74, 227, 250, 194, 173, 146, 182,
                 251, 152, 123, 172, 26, 83, 175, 194, 213, 238>>
    end

    test "returns {:error, atom} when not given valid params" do
      tx = Builder.new(ExPlasma.fee())
      assert Builder.with_nonce(tx, %{}) == {:error, :invalid_nonce_params}
    end
  end

  describe "with_nonce!/2" do
    test "returns transaction with a nonce when valid" do
      tx = Builder.new(ExPlasma.fee())

      assert tx.nonce == nil
      assert tx_with_nonce = Builder.with_nonce!(tx, %{blknum: 1000, token: <<0::160>>})
      assert %{nonce: nonce} = tx_with_nonce

      assert nonce ==
               <<61, 119, 206, 68, 25, 203, 29, 23, 147, 224, 136, 32, 198, 128, 177, 74, 227, 250, 194, 173, 146, 182,
                 251, 152, 123, 172, 26, 83, 175, 194, 213, 238>>
    end

    test "raises when not given valid params" do
      tx = Builder.new(ExPlasma.fee())

      assert_raise MatchError, fn ->
        Builder.with_nonce!(tx, %{})
      end
    end
  end

  describe "add_input/2" do
    test "adds input" do
      block_number = 99
      tx_index = 100
      oindex = 101

      assert %{inputs: [output]} =
               ExPlasma.payment_v1()
               |> Builder.new()
               |> Builder.add_input(blknum: block_number, txindex: tx_index, oindex: oindex)

      assert output.output_id.blknum == block_number
      assert output.output_id.txindex == tx_index
      assert output.output_id.oindex == oindex
    end

    test "appends new input" do
      block_number = 102
      tx_index = 103
      oindex = 104

      transaction = %Transaction{
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
        tx_type: 1
      }

      assert %{inputs: [_output, output]} =
               Builder.add_input(transaction, blknum: block_number, txindex: tx_index, oindex: oindex)

      assert output.output_id.blknum == block_number
      assert output.output_id.txindex == tx_index
      assert output.output_id.oindex == oindex
    end
  end

  describe "add_output/2" do
    test "adds the given output when given `output_data` map to the existing transaction" do
      tx = Builder.new(ExPlasma.payment_v1())

      assert tx.outputs == []

      updated_tx =
        Builder.add_output(tx, output_type: 1, output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1})

      assert updated_tx.outputs == [
               %Output{output_type: 1, output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}}
             ]
    end

    test "adds the given output when given output data to the existing transaction" do
      tx = Builder.new(ExPlasma.payment_v1())

      assert tx.outputs == []

      updated_tx = Builder.add_output(tx, output_guard: <<1::160>>, token: <<0::160>>, amount: 2)

      assert updated_tx.outputs == [
               %Output{output_type: 1, output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 2}}
             ]
    end
  end

  describe "sign/2" do
    test "returns {:ok, signed} when given valid keys" do
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

      assert {:ok, transaction} =
               ExPlasma.payment_v1()
               |> Builder.new()
               |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
               |> Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
               |> Builder.add_input(blknum: 3, txindex: 0, oindex: 0, position: 3_000_000_000)
               |> Builder.sign([key_1, key_1, key_2])

      assert [_sig_1, _sig_2, _sig_3] = transaction.sigs
    end
  end

  describe "complete flow" do
    test "builds and sign a payment v1 transaction with both inputs and outputs" do
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

      assert {:ok, txn} =
               ExPlasma.payment_v1()
               |> Builder.new(metadata: <<1::160>>, tx_data: 0)
               |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0)
               |> Builder.add_input(blknum: 2, txindex: 1, oindex: 0)
               |> Builder.add_input(blknum: 3, txindex: 0, oindex: 1)
               |> Builder.add_output(
                 output_type: 1,
                 output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: 1}
               )
               |> Builder.add_output(output_guard: <<1::160>>, token: <<0::160>>, amount: 1)
               |> Builder.add_output(output_guard: <<2::160>>, token: <<0::160>>, amount: 2)
               |> Builder.sign([key_1, key_1, key_2])

      assert txn == %Transaction{
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
               tx_data: 0,
               tx_type: 1,
               sigs: [
                 "|\e\xFF\x99\xC6\x01\x97R\xC3\xEE\xF6|\xA06:N\xC4\xD5\xF8\x99\xD6n\xB6\xB0˚\x02\x04\xCF&CM-E\xCEh\xB8\xC8N\x99\xD6\ah\xE0\x94\xD74\x17\"T\x99[\xF1\x05s9Bz\x91\xC7av\xA5\xC7\x1C",
                 "|\e\xFF\x99\xC6\x01\x97R\xC3\xEE\xF6|\xA06:N\xC4\xD5\xF8\x99\xD6n\xB6\xB0˚\x02\x04\xCF&CM-E\xCEh\xB8\xC8N\x99\xD6\ah\xE0\x94\xD74\x17\"T\x99[\xF1\x05s9Bz\x91\xC7av\xA5\xC7\x1C",
                 "ZiK\x01\xBFu\xDE\e\x99`Z}|\xCC\xD0\xD6Ah\x85\xF5SWk\xC1PZ\d\xC1\xDD7\xD21,Q\x0E\x99bc\n\xE2\x05\x13i\x8A\0\xA3\xEF\xFF\x91\x84\xE0b~_\x9A\xA7Ll\x1D\x02\xC3 \x01\xED\x1C"
               ]
             }
    end
  end
end
