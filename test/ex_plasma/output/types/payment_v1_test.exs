defmodule ExPlasma.Output.Type.PaymentV1Test do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Output.Type.PaymentV1

  alias ExPlasma.Output.Type.PaymentV1

  describe "to_map/1" do
    test "can decode amounts" do
      Enum.map(1..65_000, fn amount ->
        rlp = [<<1>>, [<<0::160>>, <<0::160>>, :binary.encode_unsigned(amount, :big)]]
        assert %{output_data: %{amount: amount}} = PaymentV1.to_map(rlp)
      end)
    end
  end

  describe "validate/1" do
    test "that amount cannot be nil" do
      output = %{output_data: %{output_guard: <<1::160>>, token: <<0::160>>, amount: nil}}
      assert_field(output, :amount, :cannot_be_nil)
    end

    test "that token cannot be nil" do
      output = %{output_data: %{output_guard: <<1::160>>, token: nil, amount: 1}}
      assert_field(output, :token, :cannot_be_nil)
    end

    test "that output_guard cannot be nil" do
      output = %{output_data: %{output_guard: nil, token: <<1::160>>, amount: 1}}
      assert_field(output, :output_guard, :cannot_be_nil)
    end

    test "that output_guard cannot be zero" do
      output = %{output_data: %{output_guard: <<0::160>>, token: <<1::160>>, amount: 1}}
      assert_field(output, :output_guard, :cannot_be_zero)
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = PaymentV1.validate(data)
  end
end
