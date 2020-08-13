defmodule ExPlasma.TransactionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  doctest ExPlasma.Transaction

  alias ExPlasma.Builder
  alias ExPlasma.Output
  alias ExPlasma.Support.TestEntity
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Type.Fee
  alias ExPlasma.Transaction.Type.PaymentV1
  alias ExPlasma.Transaction.TypeMapper

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
      ExPlasma.payment_v1()
      |> Builder.new()
      |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
      |> Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
      |> Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
      |> Builder.sign!([alice_priv, alice_priv])

    encoded_signed_tx = Transaction.encode(signed)

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

  describe "decode/2" do
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

    test "decodes successfuly a fee transaction" do
      outputs = [Fee.new_output(@alice.addr, @eth, 7)]
      {:ok, nonce} = Fee.build_nonce(%{token: @eth, blknum: 1000})
      transaction = Builder.new(ExPlasma.fee(), outputs: outputs, nonce: nonce)
      encoded_transaction = Transaction.encode(transaction)

      assert Transaction.decode(encoded_transaction, signed: false) == {:ok, transaction}
    end

    test "decodes without signatures when given the opts signed: false but an encoded signed tx", %{
      encoded_signed_tx: encoded_signed_tx
    } do
      assert {:ok, %Transaction{tx_type: 1, sigs: []}} = Transaction.decode(encoded_signed_tx, signed: false)
    end

    test "decodes without signatures when given the opts signed: false and an encoded unsigned tx", %{
      signed: signed
    } do
      unsigned = %Transaction{signed | sigs: []}
      unsigned_encoded = Transaction.encode(unsigned, signed: false)
      assert Transaction.decode(unsigned_encoded, signed: false) == {:ok, unsigned}
    end

    test "returns a malformed_rlp error when rlp is not decodable", %{encoded_signed_tx: encoded_signed_tx} do
      assert Transaction.decode("A" <> encoded_signed_tx) == {:error, :malformed_rlp}

      <<_, malformed_1::binary>> = encoded_signed_tx
      assert Transaction.decode(malformed_1) == {:error, :malformed_rlp}

      cropped_size = byte_size(encoded_signed_tx) - 1
      <<malformed_2::binary-size(cropped_size), _::binary-size(1)>> = encoded_signed_tx
      assert Transaction.decode(malformed_2) == {:error, :malformed_rlp}
    end

    test "returns a malformed_transaction error when rlp is decodable, but doesn't represent a known transaction format",
         %{sigs: sigs, inputs: inputs, outputs: outputs} do
      assert Transaction.decode(<<192>>) == {:error, :malformed_transaction}
      assert Transaction.decode(<<0x80>>) == {:error, :malformed_transaction}
      assert Transaction.decode(<<>>) == {:error, :malformed_transaction}
      assert Transaction.decode(ExRLP.encode(23)) == {:error, :malformed_transaction}
      assert Transaction.decode(ExRLP.encode([sigs, 1])) == {:error, :malformed_transaction}
      assert Transaction.decode(ExRLP.encode([sigs, 1, outputs, 0, @zero_metadata])) == {:error, :malformed_transaction}
      # looks like a payment transaction but type points to a `Transaction.Fee`, hence malformed not unrecognized
      assert Transaction.decode(ExRLP.encode([sigs, 3, inputs, outputs, 0, @zero_metadata])) ==
               {:error, :malformed_transaction}
    end

    test "returns a unrecognized_transaction_type error when given an unkown/invalid transaction type", %{
      sigs: sigs,
      inputs: inputs,
      outputs: outputs
    } do
      assert Transaction.decode(ExRLP.encode([sigs, ["bad"], inputs, outputs, 0, @zero_metadata])) ==
               {:error, :unrecognized_transaction_type}

      assert Transaction.decode(ExRLP.encode([sigs, 234_567, inputs, outputs, 0, @zero_metadata])) ==
               {:error, :unrecognized_transaction_type}
    end

    test "returns a malformed_witnesses error when given something else than a list for witnesses", %{
      inputs: inputs,
      outputs: outputs
    } do
      assert Transaction.decode(ExRLP.encode([<<1>>, @payment_tx_type, inputs, outputs, 0, @zero_metadata])) ==
               {:error, :malformed_witnesses}
    end

    test "returns a malformed_inputs error when given malformated inputs", %{sigs: sigs, outputs: outputs} do
      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, 42, outputs, 0, @zero_metadata])) ==
               {:error, :malformed_inputs}

      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, [[1, 2]], outputs, 0, @zero_metadata])) ==
               {:error, :malformed_inputs}

      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, [[1, 2, 'a']], outputs, 0, @zero_metadata])) ==
               {:error, :malformed_inputs}
    end

    test "returns a malformed_outputs error when given malformated outputs", %{
      sigs: sigs,
      inputs: inputs,
      alice_addr: alice_addr
    } do
      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, 42, 0, @zero_metadata])) ==
               {:error, :malformed_outputs}

      assert Transaction.decode(
               ExRLP.encode([
                 sigs,
                 @payment_tx_type,
                 inputs,
                 [[@payment_output_type, alice_addr, alice_addr, 1]],
                 0,
                 @zero_metadata
               ])
             ) == {:error, :malformed_outputs}

      assert Transaction.decode(
               ExRLP.encode([
                 sigs,
                 @payment_tx_type,
                 inputs,
                 [[@payment_output_type, [alice_addr, alice_addr]]],
                 0,
                 @zero_metadata
               ])
             ) == {:error, :malformed_outputs}

      assert Transaction.decode(
               ExRLP.encode([
                 sigs,
                 @payment_tx_type,
                 inputs,
                 [[@payment_output_type, [alice_addr, alice_addr, 'a']]],
                 0,
                 @zero_metadata
               ])
             ) == {:error, :malformed_outputs}

      assert Transaction.decode(
               ExRLP.encode([
                 sigs,
                 @payment_tx_type,
                 inputs,
                 [[<<232>>, [alice_addr, alice_addr, 1]]],
                 0,
                 @zero_metadata
               ])
             ) == {:error, :malformed_outputs}

      assert Transaction.decode(
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
      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, [<<6>>], @zero_metadata])) ==
               {:error, :malformed_tx_data}

      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, @zero_metadata, @zero_metadata])) ==
               {:error, :malformed_tx_data}

      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, <<1::256>>, @zero_metadata])) ==
               {:error, :malformed_tx_data}
    end

    test "returns a malformed_metadata error when given malformated metadata", %{
      sigs: sigs,
      inputs: inputs,
      outputs: outputs
    } do
      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, 0, ""])) ==
               {:error, :malformed_metadata}

      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, 0, []])) ==
               {:error, :malformed_metadata}

      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, 0, <<1::224>>])) ==
               {:error, :malformed_metadata}

      assert Transaction.decode(ExRLP.encode([sigs, @payment_tx_type, inputs, outputs, 0, <<2::288>>])) ==
               {:error, :malformed_metadata}
    end
  end

  describe "with_nonce/2" do
    test "returns {:ok, transaction} with a nonce when valid" do
      tx = Builder.new(ExPlasma.fee())

      assert tx.nonce == nil
      assert {:ok, tx_with_nonce} = Transaction.with_nonce(tx, %{blknum: 1000, token: <<0::160>>})
      assert %{nonce: nonce} = tx_with_nonce

      assert nonce ==
               <<61, 119, 206, 68, 25, 203, 29, 23, 147, 224, 136, 32, 198, 128, 177, 74, 227, 250, 194, 173, 146, 182,
                 251, 152, 123, 172, 26, 83, 175, 194, 213, 238>>
    end

    test "returns {:error, atom} when not given valid params" do
      tx = Builder.new(ExPlasma.fee())
      assert Transaction.with_nonce(tx, %{}) == {:error, :invalid_nonce_params}
    end
  end

  describe "validate/1" do
    test "returns :ok when the transaction is valid", %{signed: signed} do
      assert Transaction.validate(signed) == :ok
    end

    test "returns a malformed_witness error when not given list of valid length binary for sigs", %{
      signed: signed
    } do
      error = {:error, {:witnesses, :malformed_witnesses}}

      assert Transaction.validate(%Transaction{signed | sigs: [[1], [2]]}) == error
      assert Transaction.validate(%Transaction{signed | sigs: [[1, 2]]}) == error
      assert Transaction.validate(%Transaction{signed | sigs: [1, 2]}) == error
      assert Transaction.validate(%Transaction{signed | sigs: [<<1>>, <<1>>]}) == error
    end

    test "forward validation to underlying transaction" do
      %{priv_encoded: alice_priv} = @alice
      %{addr: bob_addr} = @bob

      signed =
        ExPlasma.payment_v1()
        |> Builder.new()
        |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
        |> Builder.sign!([alice_priv, alice_priv])

      assert Transaction.validate(signed) == {:error, {:inputs, :duplicate_inputs}}
    end
  end

  describe "to_map/2" do
    test "maps an rlp list starting with a list of sigs into a Transaction structure", %{signed: signed} do
      rlp = Transaction.to_rlp(signed)

      assert {:ok, mapped} = Transaction.to_map(rlp)
      assert mapped == signed
    end

    test "maps an rlp list starting with a type into a Transaction structure", %{signed: signed} do
      [_sigs | typed_rlp] = Transaction.to_rlp(signed)

      assert {:ok, mapped} = Transaction.to_map(typed_rlp)
      assert mapped == %{signed | sigs: []}
    end

    test "returns malformed_transaction error when the transaction is malformed" do
      assert Transaction.to_map(123) == {:error, :malformed_transaction}
      assert Transaction.to_map([[], []]) == {:error, :malformed_transaction}
    end

    test "returns `unrecognized_transaction_type` when the given type is not supported (with sigs)" do
      assert Transaction.to_map([[], <<1337>>, <<0>>]) == {:error, :unrecognized_transaction_type}
    end

    test "returns `unrecognized_transaction_type` when the given type is not supported" do
      assert Transaction.to_map([<<1337>>, <<0>>]) == {:error, :unrecognized_transaction_type}
    end
  end

  describe "to_rlp/1" do
    test "returns the RLP list of a fee transaction" do
      outputs = [Fee.new_output(@alice.addr, @eth, 7)]
      {:ok, nonce} = Fee.build_nonce(%{token: @eth, blknum: 1000})
      transaction = Builder.new(ExPlasma.fee(), outputs: outputs, nonce: nonce)
      rlp = Transaction.to_rlp(transaction)

      assert [[], tx_type, outputs, nonce] = rlp

      assert is_binary(tx_type)
      assert is_list(outputs)
      assert is_binary(nonce)
    end

    test "returns the RLP list of a payment v1 transaction", %{signed: signed} do
      rlp = Transaction.to_rlp(signed)

      assert [sigs, tx_type, inputs, outputs, 0, metadata] = rlp

      assert sigs == signed.sigs
      assert is_binary(tx_type)
      assert is_list(inputs)
      assert is_list(outputs)
      assert is_binary(metadata)
    end
  end

  describe "with_witnesses/1" do
    test "decorates the signed transaction by recovering the witnesses", %{signed: signed, alice_addr: alice_addr} do
      assert signed.witnesses == []

      assert {:ok, %{witnesses: witnesses}} = Transaction.with_witnesses(signed)
      assert witnesses == [alice_addr, alice_addr]
    end

    test "returns a corrupted_witness error when given a list containing a malformed witness", %{
      sigs: sigs,
      signed: signed
    } do
      [sig_1, sig_2] = sigs
      error = {:error, :corrupted_witness}

      assert Transaction.with_witnesses(%{signed | sigs: [<<1>>, <<1>>]}) == error
      assert Transaction.with_witnesses(%{signed | sigs: [sig_1, <<1::size(520)>>]}) == error
      assert Transaction.with_witnesses(%{signed | sigs: [<<1::size(520)>>, sig_2]}) == error
    end
  end

  describe "sign/2" do
    test "returns {:ok, signed} when given valid keys" do
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

      tx =
        ExPlasma.payment_v1()
        |> Builder.new()
        |> Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
        |> Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
        |> Builder.add_input(blknum: 3, txindex: 0, oindex: 0, position: 3_000_000_000)

      assert {:ok, %Transaction{} = signed} = Transaction.sign(tx, [key_1, key_1, key_2])
      assert [sig_1, sig_1, sig_2] = signed.sigs
    end

    test "returns {:error, :not_signable} when given an invalid struct" do
      %{priv_encoded: key_1} = @alice
      %{priv_encoded: key_2} = @bob

      assert Transaction.sign(%{}, [key_1, key_1, key_2]) == {:error, :not_signable}
    end
  end

  describe "encode/2" do
    test "encodes a fee transaction struct" do
      outputs = [Fee.new_output(@alice.addr, @eth, 7)]
      {:ok, nonce} = Fee.build_nonce(%{token: @eth, blknum: 1000})
      transaction = Builder.new(ExPlasma.fee(), outputs: outputs, nonce: nonce)
      result = Transaction.encode(transaction)

      expected_result =
        <<248, 82, 192, 3, 238, 237, 2, 235, 148, 99, 100, 231, 104, 170, 156, 129, 68, 252, 45, 124, 232, 218, 107,
          175, 51, 13, 180, 254, 40, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 160, 61, 119,
          206, 68, 25, 203, 29, 23, 147, 224, 136, 32, 198, 128, 177, 74, 227, 250, 194, 173, 146, 182, 251, 152, 123,
          172, 26, 83, 175, 194, 213, 238>>

      assert result == expected_result
    end

    test "encodes a payment v1 transaction struct", %{signed: signed} do
      result = Transaction.encode(signed)

      expected_result =
        <<249, 1, 30, 248, 134, 184, 65, 127, 174, 77, 180, 234, 189, 49, 84, 179, 178, 148, 52, 166, 45, 173, 243, 146,
          232, 83, 50, 11, 20, 70, 155, 157, 104, 124, 129, 171, 218, 211, 160, 84, 33, 174, 245, 63, 10, 168, 2, 228,
          234, 173, 30, 198, 141, 224, 197, 38, 21, 39, 255, 167, 30, 150, 31, 201, 208, 59, 206, 122, 90, 86, 206, 27,
          184, 65, 127, 174, 77, 180, 234, 189, 49, 84, 179, 178, 148, 52, 166, 45, 173, 243, 146, 232, 83, 50, 11, 20,
          70, 155, 157, 104, 124, 129, 171, 218, 211, 160, 84, 33, 174, 245, 63, 10, 168, 2, 228, 234, 173, 30, 198,
          141, 224, 197, 38, 21, 39, 255, 167, 30, 150, 31, 201, 208, 59, 206, 122, 90, 86, 206, 27, 1, 248, 66, 160, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 154, 202, 0, 160, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 119, 53, 148, 0, 238, 237, 1,
          235, 148, 70, 55, 228, 199, 167, 80, 4, 228, 159, 169, 40, 95, 34, 176, 220, 96, 12, 124, 194, 203, 148, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 128, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

      assert expected_result == result
    end

    test "encodes without signatures when given the opts signed: false", %{signed: signed} do
      refute signed.sigs == []
      encoded_unsigned_tx = Transaction.encode(signed, signed: false)
      assert [_payment_marker, _inputs, _outputs, _txdata, _metadata] = ExRLP.decode(encoded_unsigned_tx)

      expected_result =
        <<248, 150, 1, 248, 66, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          59, 154, 202, 0, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 119,
          53, 148, 0, 238, 237, 1, 235, 148, 70, 55, 228, 199, 167, 80, 4, 228, 159, 169, 40, 95, 34, 176, 220, 96, 12,
          124, 194, 203, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 128, 160, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

      assert expected_result == encoded_unsigned_tx
    end
  end

  describe "hash/1" do
    test "calculates transaction hash for struct", %{signed: signed} do
      result = Transaction.hash(signed)

      expected_result =
        <<105, 141, 249, 154, 54, 160, 13, 35, 161, 231, 99, 13, 206, 227, 150, 12, 97, 25, 184, 143, 201, 55, 30, 48,
          19, 54, 34, 199, 95, 115, 237, 56>>

      assert result == expected_result
    end

    test "calculates hash for rlp encoded transaction", %{signed: signed} do
      result = signed |> Transaction.encode(signed: false) |> Transaction.hash()

      expected_result =
        <<105, 141, 249, 154, 54, 160, 13, 35, 161, 231, 99, 13, 206, 227, 150, 12, 97, 25, 184, 143, 201, 55, 30, 48,
          19, 54, 34, 199, 95, 115, 237, 56>>

      assert result == expected_result
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
             ExPlasma.payment_v1()
             |> Builder.new(inputs: inputs, outputs: outputs)
             |> Builder.sign(privs)

    encoded_signed_tx = Transaction.encode(signed)

    assert {:ok, ^signed} = Transaction.decode(encoded_signed_tx)
  end
end
