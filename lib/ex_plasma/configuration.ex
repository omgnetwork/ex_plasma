defmodule ExPlasma.Configuration do
  @moduledoc """
  Provides access to applications configuration with additional validation.

  Application variables should be retrieved using this module
  instead of calling Application.get_env/3
  """

  @app :ex_plasma

  @type eip_712_domain_t() :: %{
          name: String.t(),
          salt: String.t(),
          verifying_contract: String.t(),
          version: String.t()
        }

  @doc """
  Retrieve the eip 712 domain from the config and validates its format.
  The expected format is:
  %{
      name: "OMG Network",
      salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
      verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
      version: "1"
  }

  Returns the domain if valid, or raise an exception otherwise.

  ## Example

  iex> Application.put_env(:ex_plasma, :eip_712_domain, %{
  ...>    name: "OMG Network",
  ...>    salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
  ...>    verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
  ...>    version: "1"
  ...>})
  iex> ExPlasma.Configuration.eip_712_domain()
  %{
      name: "OMG Network",
      salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
      verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
      version: "1"
  }
  """
  @spec eip_712_domain() :: eip_712_domain_t() | no_return()
  def eip_712_domain() do
    @app
    |> Application.get_env(:eip_712_domain)
    |> validate_eip_712_domain()
  end

  defp validate_eip_712_domain(%{name: name, salt: "0x" <> _, verifying_contract: "0x" <> _, version: version} = domain)
       when is_binary(name) and is_binary(version) do
    domain
  end

  defp validate_eip_712_domain(_) do
    raise RuntimeError, """
    :eip_712_domain config is invalid. It must be in the following format:
    %{
      name: "OMG Network",
      salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
      verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
      version: "1"
    }
    """
  end
end
