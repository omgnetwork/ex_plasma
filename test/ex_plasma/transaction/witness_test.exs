defmodule ExPlasma.Transaction.WitnessTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExPlasma.Transaction.Witness

  describe "valid?/1" do
    test "returns true when is binary and 65 bytes long" do
      assert Witness.valid?(<<0::520>>)
    end

    test "returns false when not a binary" do
      refute Witness.valid?([<<0>>])
    end

    test "returns false when not 65 bytes long" do
      refute Witness.valid?(<<0>>)
    end
  end
end
