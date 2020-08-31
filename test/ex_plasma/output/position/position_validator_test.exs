defmodule ExPlasma.Output.Position.ValidatorTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExPlasma.Output.Position.Validator

  describe "validate_blknum/1" do
    test "returns :ok when valid" do
      assert Validator.validate_blknum(1000) == :ok
    end

    test "returns an error when blknum is nil" do
      assert Validator.validate_blknum(nil) == {:error, {:blknum, :cannot_be_nil}}
    end

    test "returns an error when blknum exceed maximum value" do
      assert Validator.validate_blknum(1_000_000_000_000_000_000) == {:error, {:blknum, :cannot_exceed_maximum_value}}
    end

    test "returns an error when blknum is not an integer" do
      assert Validator.validate_blknum("a") == {:error, {:blknum, :must_be_an_integer}}
    end
  end

  describe "validate_txindex/1" do
    test "returns :ok when valid" do
      assert Validator.validate_txindex(1000) == :ok
    end

    test "returns an error when txindex is nil" do
      assert Validator.validate_txindex(nil) == {:error, {:txindex, :cannot_be_nil}}
    end

    test "returns an error when txindex exceed maximum value" do
      assert Validator.validate_txindex(1_000_000_000_000_000_000) == {:error, {:txindex, :cannot_exceed_maximum_value}}
    end

    test "returns an error when txindex is not an integer" do
      assert Validator.validate_txindex("a") == {:error, {:txindex, :must_be_an_integer}}
    end
  end

  describe "validate_oindex/1" do
    test "returns :ok when valid" do
      assert Validator.validate_oindex(1000) == :ok
    end

    test "returns an error when oindex is nil" do
      assert Validator.validate_oindex(nil) == {:error, {:oindex, :cannot_be_nil}}
    end

    test "returns an error when oindex is not an integer" do
      assert Validator.validate_oindex("a") == {:error, {:oindex, :must_be_an_integer}}
    end
  end
end
