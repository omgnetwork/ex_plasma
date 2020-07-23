defmodule ExPlasma.Transaction.RecoveredTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExPlasma.Output
  alias ExPlasma.PaymentV1Builder
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Recovered
  alias ExPlasma.Transaction.Type.PaymentV1
  alias ExPlasma.Transaction.TypeMapper
  alias ExPlasma.Support.TestEntity

  @alice TestEntity.alice()
  @bob TestEntity.bob()
  @eth <<0::160>>
  @zero_metadata <<0::256>>

  @payment_tx_type TypeMapper.tx_type_for(:tx_payment_v1)
  @payment_output_type TypeMapper.output_type_for(:output_payment_v1)

  setup_all do
    %{priv_encoded: alice_priv, addr: alice_addr} = @alice
    %{addr: bob_addr} = @bob

    signed =
      PaymentV1Builder.new()
      |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
      |> PaymentV1Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
      |> PaymentV1Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
      |> PaymentV1Builder.sign!(keys: [alice_priv, alice_priv])

    encoded_signed_tx = signed |> Transaction.encode()

    [sigs, _payment_marker, inputs, outputs, _txdata, _metadata] = ExRLP.decode(encoded_signed_tx)

    {:ok,
     %{
       alice_addr: alice_addr,
       bob_addr: bob_addr,
       signed: signed,
       encoded_signed_tx: encoded_signed_tx,
       sigs: sigs,
       inputs: inputs,
       outputs: outputs
     }}
  end

  describe "decode/1" do
    test "decodes successfuly in various empty input/output combinations" do
      transaction_list = [
        {[], [], [{@alice, @eth, 7}]},
        {[{1, 2, 3}], [@alice], [{@alice, @eth, 7}]},
        {[{1, 2, 3}], [@alice], [{@alice, @eth, 7}, {@bob, @eth, 3}]},
        {[{1, 2, 3}, {2, 3, 4}], [@alice, @bob], [{@alice, @eth, 7}, {@bob, @eth, 3}]},
        {[{1, 2, 3}, {2, 3, 4}, {2, 3, 5}], [@alice, @bob, @bob], [{@alice, @eth, 7}, {@bob, @eth, 3}]},
        {[{1, 2, 3}, {2, 3, 4}, {2, 3, 5}], [@alice, @bob, @bob],
         [{@alice, @eth, 7}, {@bob, @eth, 3}, {@bob, @eth, 3}]},
        {[{1, 2, 3}, {2, 3, 1}, {2, 3, 2}, {3, 3, 4}], [@alice, @alice, @bob, @bob],
         [{@alice, @eth, 7}, {@alice, @eth, 3}, {@bob, @eth, 7}, {@bob, @eth, 3}]}
      ]

      Enum.map(transaction_list, &decode_tester/1)
    end

    test "decodes the given signed bytes and returns a Recovered struct", %{
      encoded_signed_tx: encoded_signed_tx,
      signed: signed,
      alice_addr: alice_addr
    } do
      assert {:ok, %Recovered{} = recovered} = Recovered.decode(encoded_signed_tx)

      assert recovered.witnesses == [alice_addr, alice_addr]

      assert recovered.tx_hash ==
               <<105, 138, 209, 67, 72, 153, 74, 64, 78, 147, 15, 112, 115, 192, 114, 88, 191, 52, 85, 163, 90, 141,
                 248, 68, 157, 239, 101, 31, 201, 6, 111, 33>>

      assert recovered.signed_tx_bytes == encoded_signed_tx

      assert recovered.signed_tx == signed
    end

    test "returns a malformed_rlp error when rlp is not decodable", %{encoded_signed_tx: encoded_signed_tx} do
      assert Recovered.decode("A" <> encoded_signed_tx) == {:error, :malformed_rlp}

      <<_, malformed_1::binary>> = encoded_signed_tx
      assert Recovered.decode(malformed_1) == {:error, :malformed_rlp}

      cropped_size = byte_size(encoded_signed_tx) - 1
      <<malformed_2::binary-size(cropped_size), _::binary-size(1)>> = encoded_signed_tx
      assert Recovered.decode(malformed_2) == {:error, :malformed_rlp}
    end

    test "returns a malformed_transaction error when rlp is decodable, but doesn't represent a known transaction format",
         %{sigs: sigs, inputs: inputs, outputs: outputs} do
      assert Recovered.decode(<<192>>) == {:error, :malformed_transaction}
      assert Recovered.decode(<<0x80>>) == {:error, :malformed_transaction}
      assert Recovered.decode(<<>>) == {:error, :malformed_transaction}
      assert Recovered.decode(ExRLP.encode(23)) == {:error, :malformed_transaction}
      assert Recovered.decode(ExRLP.encode([sigs, 1])) == {:error, :malformed_transaction}
      # looks like a payment transaction but type points to a `Transaction.Fee`, hence malformed not unrecognized
      assert Recovered.decode(ExRLP.encode([sigs, 3, inputs, outputs, 0, @zero_metadata])) ==
               {:error, :malformed_transaction}

      assert Recovered.decode(ExRLP.encode([sigs, 1, outputs, 0, @zero_metadata])) == {:error, :malformed_transaction}
    end

    test "returns a unrecognized_transaction_type error when given an unkown/invalid transaction type", %{
      sigs: sigs,
      inputs: inputs,
      outputs: outputs
    } do
      assert Recovered.decode(ExRLP.encode([sigs, ["bad"], inputs, outputs, 0, @zero_metadata])) ==
               {:error, :unrecognized_transaction_type}

      assert Recovered.decode(ExRLP.encode([sigs, []])) == {:error, :unrecognized_transaction_type}

      assert Recovered.decode(ExRLP.encode([sigs, 234_567, inputs, outputs, 0, @zero_metadata])) ==
               {:error, :unrecognized_transaction_type}
    end

    test "returns a malformed_witnesses error when given something else than a list for witnesses", %{
      sigs: sigs,
      inputs: inputs,
      outputs: outputs
    } do
      assert Recovered.decode(ExRLP.encode([<<1>>, @payment_tx_type, inputs, outputs, 0, @zero_metadata])) ==
               {:error, :malformed_witnesses}

      assert Recovered.decode(ExRLP.encode([[sigs], @payment_tx_type, inputs, outputs, 0, @zero_metadata])) ==
               {:error, :malformed_witnesses}
    end

    test "returns a corrupted_witness error when given a list containing a malformed witness", %{
      sigs: sigs,
      inputs: inputs,
      outputs: outputs
    } do
      [sig_1, sig_2] = sigs

      assert Recovered.decode(ExRLP.encode([[<<1>>, <<1>>], @payment_tx_type, inputs, outputs, 0, @zero_metadata])) ==
               {:error, :corrupted_witness}

      assert Recovered.decode(
               ExRLP.encode([[sig_1, <<1::size(520)>>], @payment_tx_type, inputs, outputs, 0, @zero_metadata])
             ) == {:error, :corrupted_witness}

      assert Recovered.decode(
               ExRLP.encode([[<<1::size(520)>>, sig_2], @payment_tx_type, inputs, outputs, 0, @zero_metadata])
             ) == {:error, :corrupted_witness}
    end

    test "returns a malformed_inputs error when given malformated inputs", %{sigs: sigs, outputs: outputs} do
      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, 42, outputs, 0, @zero_metadata])) ==
               {:error, :malformed_inputs}

      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, [[1, 2]], outputs, 0, @zero_metadata])) ==
               {:error, :malformed_inputs}

      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, [[1, 2, 'a']], outputs, 0, @zero_metadata])) ==
               {:error, :malformed_inputs}
    end

    test "returns a malformed_outputs error when given malformated outputs", %{
      sigs: sigs,
      inputs: inputs,
      alice_addr: alice_addr
    } do
      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, 42, 0, @zero_metadata])) ==
               {:error, :malformed_outputs}

      assert Recovered.decode(
               ExRLP.encode([
                 sigs,
                 @payment_tx_type,
                 inputs,
                 [[@payment_output_type, alice_addr, alice_addr, 1]],
                 0,
                 @zero_metadata
               ])
             ) == {:error, :malformed_outputs}

      assert Recovered.decode(
               ExRLP.encode([
                 sigs,
                 @payment_tx_type,
                 inputs,
                 [[@payment_output_type, [alice_addr, alice_addr]]],
                 0,
                 @zero_metadata
               ])
             ) == {:error, :malformed_outputs}

      assert Recovered.decode(
               ExRLP.encode([
                 sigs,
                 @payment_tx_type,
                 inputs,
                 [[@payment_output_type, [alice_addr, alice_addr, 'a']]],
                 0,
                 @zero_metadata
               ])
             ) == {:error, :malformed_outputs}

      assert Recovered.decode(
               ExRLP.encode([
                 sigs,
                 @payment_tx_type,
                 inputs,
                 [[<<232>>, [alice_addr, alice_addr, 1]]],
                 0,
                 @zero_metadata
               ])
             ) == {:error, :malformed_outputs}

      assert Recovered.decode(
               ExRLP.encode([
                 sigs,
                 @payment_tx_type,
                 inputs,
                 [[@payment_output_type, [alice_addr, alice_addr, [1]]]],
                 0,
                 @zero_metadata
               ])
             ) == {:error, :malformed_outputs}
    end

    test "returns a malformed_tx_data error when given malformated tx data", %{
      sigs: sigs,
      inputs: inputs,
      outputs: outputs
    } do
      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, [<<6>>], @zero_metadata])) ==
               {:error, :malformed_tx_data}

      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, @zero_metadata, @zero_metadata])) ==
               {:error, :malformed_tx_data}

      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, <<1::256>>, @zero_metadata])) ==
               {:error, :malformed_tx_data}
    end

    test "returns a malformed_metadata error when given malformated metadata", %{
      sigs: sigs,
      inputs: inputs,
      outputs: outputs
    } do
      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, 0, ""])) ==
               {:error, :malformed_metadata}

      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, 0, []])) ==
               {:error, :malformed_metadata}

      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, 0, <<1::224>>])) ==
               {:error, :malformed_metadata}

      assert Recovered.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, 0, <<2::288>>])) ==
               {:error, :malformed_metadata}
    end
  end

  describe "validate/1" do
    test "forward validation to protocol" do
      %{priv_encoded: alice_priv} = @alice
      %{addr: bob_addr} = @bob

      signed =
        PaymentV1Builder.new()
        |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> PaymentV1Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
        |> PaymentV1Builder.sign!(keys: [alice_priv, alice_priv])

      {:ok, recovered} = signed |> Transaction.encode() |> Recovered.decode()

      assert Recovered.validate(recovered) == {:error, {:inputs, :duplicate_inputs}}
    end
  end

  defp decode_tester({inputs, sigs, outputs}) do
    inputs =
      Enum.map(inputs, fn {blknum, txindex, oindex} ->
        output_id = %{blknum: blknum, txindex: txindex, oindex: oindex}
        position = Output.Position.pos(output_id)
        %Output{output_id: Map.put(output_id, :position, position)}
      end)

    outputs =
      Enum.map(outputs, fn {%{addr: addr}, token, amount} ->
        PaymentV1.new_output(addr, token, amount)
      end)

    privs = Enum.map(sigs, & &1.priv_encoded)

    assert {:ok, signed} =
             inputs
             |> PaymentV1.new(outputs)
             |> Transaction.sign(keys: privs)

    encoded_signed_tx = Transaction.encode(signed)

    witnesses = Enum.map(sigs, & &1.addr)

    assert {:ok,
            %Transaction.Recovered{
              signed_tx: ^signed,
              witnesses: ^witnesses
            }} = Recovered.decode(encoded_signed_tx)
  end
end
