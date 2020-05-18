defmodule ExPlasma.Configuration.ValidatorTest do
  use ExUnit.Case, async: true
  alias ExPlasma.Configuration.Validator

  doctest ExPlasma.Configuration.Validator

  describe "validate_eip_712_domain/1" do
    @valid_domain %{
      name: "OMG Network",
      salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
      verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
      version: "1"
    }

    test "returns the domain if correctly valid" do
      assert Validator.validate_eip_712_domain(@valid_domain) == @valid_domain
    end

    test "raises when given an invalid domain" do
      invalid_values = %{name: 123, salt: "invalid", verifying_contract: "invalid", version: 1}

      Enum.each(invalid_values, fn {key, invalid_value} ->
        invalid_domain = Map.put(@valid_domain, key, invalid_value)

        assert_raise RuntimeError, ~r"eip_712_domain config is invalid.", fn ->
          Validator.validate_eip_712_domain(invalid_domain)
        end
      end)
    end
  end
end
