defmodule ExPlasma.Output.Type.AbstractPayment.ValidatorTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Output.Type.AbstractPayment.Validator

  describe "validate_amount/1" do
    test "returns :ok when valid" do
      assert Validator.validate_amount(1000) == :ok
    end

    test "returns an error when amount is nil" do
      assert Validator.validate_amount(nil) == {:error, {:amount, :cannot_be_nil}}
    end

    test "returns an error when amount is zero" do
      assert Validator.validate_amount(0) == {:error, {:amount, :cannot_be_zero}}
    end
  end

  describe "validate_token/1" do
    test "returns :ok when valid" do
      assert Validator.validate_token(<<0::160>>) == :ok
    end

    test "returns an error when token is nil" do
      assert Validator.validate_token(nil) == {:error, {:token, :cannot_be_nil}}
    end
  end

  describe "validate_output_guard/1" do
    test "returns :ok when valid" do
      assert Validator.validate_output_guard(<<1::160>>) == :ok
    end

    test "returns an error when output_guard is nil" do
      assert Validator.validate_output_guard(nil) == {:error, {:output_guard, :cannot_be_nil}}
    end

    test "returns an error when output_guard is zero" do
      assert Validator.validate_output_guard(<<0::160>>) == {:error, {:output_guard, :cannot_be_zero}}
    end
  end
end
