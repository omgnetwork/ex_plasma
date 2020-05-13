defmodule ExPlasma.ConfigurationTest do
  # We need async: false as we are manipulating application variables which may be used by other tests
  use ExUnit.Case, async: false
  alias ExPlasma.Configuration

  doctest ExPlasma.Configuration

  @app :ex_plasma

  describe "eip_712_domain/1" do
    @valid_domain %{
      name: "OMG Network",
      salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
      verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
      version: "1"
    }

    setup do
      # Restore the default value when the test is done
      current_value = Application.get_env(@app, :eip_712_domain)

      on_exit(fn ->
        set_domain(current_value)
      end)
    end

    test "retrive the domain if correctly configured" do
      set_domain(@valid_domain)

      assert Configuration.eip_712_domain() == @valid_domain
    end

    test "raises when given invalid data" do
      invalid_values = %{name: 123, salt: "invalid", verifying_contract: "invalid", version: 1}

      Enum.map(invalid_values, fn {key, invalid_value} ->
        @valid_domain
        |> Map.put(key, invalid_value)
        |> set_domain()

        assert_raise RuntimeError, ~r"eip_712_domain config is invalid.", fn ->
          Configuration.eip_712_domain()
        end
      end)
    end

    defp set_domain(domain), do: Application.put_env(@app, :eip_712_domain, domain)
  end
end
