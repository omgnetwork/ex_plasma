defmodule ExPlasma.Output.Type.PaymentV1Test do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest ExPlasma.Output.Type.PaymentV1

  alias ExPlasma.Output.Type.PaymentV1

  describe "validate/1" do
    test "that amount cannot be nil" do
      position = %{output_guard: <<1::160>>, token: <<0::160>>, amount: nil}
      assert_field(position, :amount, :cannot_be_nil)
    end

    test "that token cannot be nil" do
      position = %{output_guard: <<1::160>>, token: nil, amount: 1}
      assert_field(position, :token, :cannot_be_nil)
    end

    test "that output_guard cannot be nil" do
      position = %{output_guard: nil, token: <<1::160>>, amount: 1}
      assert_field(position, :output_guard, :cannot_be_nil)
    end

    test "that output_guard cannot be zero" do
      position = %{output_guard: <<0::160>>, token: <<1::160>>, amount: 1}
      assert_field(position, :output_guard, :cannot_be_zero)
    end
  end

  defp assert_field(data, field, message) do
    assert {:error, {^field, ^message}} = PaymentV1.validate(data)
  end
end
