defmodule ExPlasma do
  @moduledoc """
  Documentation for ExPlasma.
  """

  @spec authority_address() :: String.t()
  def authority_address(), do:
    Application.get_env(:ex_plasma, :authority_address)

  @spec contract_address() :: String.t()
  def contract_address(), do:
    Application.get_env(:ex_plasma, :contract_address)
  
  @spec eth_vault_address() :: String.t()
  def eth_vault_address(), do:
    Application.get_env(:ex_plasma, :eth_vault_address)
end
