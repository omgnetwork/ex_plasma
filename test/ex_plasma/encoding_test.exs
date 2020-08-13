defmodule ExPlasma.EncodingTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Encoding

  alias ExPlasma.Encoding

  describe "to_hex/1" do
    test "converts int to hex" do
      assert Encoding.to_hex(10) == "0xA"
    end

    test "converts binary to hex" do
      assert 10
             |> :binary.encode_unsigned()
             |> Encoding.to_hex() == "0x0a"
    end
  end

  describe "to_int/1" do
    test "converts hex to int" do
      assert Encoding.to_int("0xA") == 10
    end

    test "converts binary to int" do
      assert 10
             |> :binary.encode_unsigned()
             |> Encoding.to_int() == 10
    end
  end

  describe "to_binary/1" do
    test "converts hex to binary" do
      assert Encoding.to_binary("0x0a") == {:ok, "\n"}
    end
  end
end
