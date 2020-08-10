defmodule ExPlasma.Transaction.SignedTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExPlasma.PaymentV1Builder
  alias ExPlasma.Support.TestEntity
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Signed
  alias ExPlasma.Transaction.Type.PaymentV1

  @alice TestEntity.alice()
  @bob TestEntity.bob()
  @eth <<0::160>>

  setup_all do
    %{priv_encoded: alice_priv, addr: alice_addr} = @alice
    %{addr: bob_addr} = @bob

    signed =
      PaymentV1Builder.new()
      |> PaymentV1Builder.add_input(blknum: 1, txindex: 0, oindex: 0, position: 1_000_000_000)
      |> PaymentV1Builder.add_input(blknum: 2, txindex: 0, oindex: 0, position: 2_000_000_000)
      |> PaymentV1Builder.add_output(output_guard: bob_addr, token: @eth, amount: 12)
      |> PaymentV1Builder.sign!([alice_priv, alice_priv])

    encoded_signed_tx = Transaction.encode(signed)

    {:ok,
     %{
       alice_addr: alice_addr,
       signed: signed,
       encoded_signed_tx: encoded_signed_tx
     }}
  end

  describe "get_witnesses/1" do
    test "returns {:ok, addresses} when signatures are valid", %{signed: signed, alice_addr: alice_addr} do
      assert {:ok, witnesses} = Signed.get_witnesses(signed)
      assert witnesses == [alice_addr, alice_addr]
    end

    test "returns {:error, :corrupted_witness} when the signature is invalid" do
      signed = %Signed{raw_tx: %PaymentV1{}, sigs: [<<1>>]}

      assert Signed.get_witnesses(signed) == {:error, :corrupted_witness}
    end
  end
end
