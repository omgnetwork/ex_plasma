defmodule ExPlasma.Configuration.Validator do
  @moduledoc """
  Provides validation to application variables
  """

  @type eip_712_domain_t() :: %{
          name: String.t(),
          salt: String.t(),
          verifying_contract: String.t(),
          version: String.t()
        }

  @doc """
  Validates the eip 712 domain format.
  The expected format is:
  %{
      name: "OMG Network",
      salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
      verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
      version: "2"
  }

  Returns the domain if valid, or raise an exception otherwise.

  ## Example

      iex> ExPlasma.Configuration.Validator.validate_eip_712_domain(%{
      ...>    name: "OMG Network",
      ...>    salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
      ...>    verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
      ...>    version: "2"
      ...>})
      %{
          name: "OMG Network",
          salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
          verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
          version: "2"
      }
  """
  @spec validate_eip_712_domain(any()) :: eip_712_domain_t() | no_return()
  def validate_eip_712_domain(%{name: name, salt: "0x" <> _, verifying_contract: "0x" <> _, version: version} = domain)
      when is_binary(name) and is_binary(version) do
    domain
  end

  def validate_eip_712_domain(_) do
    raise RuntimeError, """
    :eip_712_domain config is invalid. It must be in the following format:
    %{
      name: "OMG Network",
      salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
      verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
      version: "2"
    }
    """
  end
end
