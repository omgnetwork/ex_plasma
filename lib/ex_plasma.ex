defmodule ExPlasma do
  @moduledoc """
  Documentation for ExPlasma.
  """

  @spec authority_address() :: String.t()
  def authority_address(), do: Application.get_env(:ex_plasma, :authority_address)

  @spec contract_address() :: String.t()
  def contract_address(), do: Application.get_env(:ex_plasma, :contract_address)

  @spec eth_vault_address() :: String.t()
  def eth_vault_address(), do: Application.get_env(:ex_plasma, :eth_vault_address)

  @spec exit_game_address() :: String.t()
  def exit_game_address(),  do: Application.get_env(:ex_plasma, :exit_game_address)

  @spec gas() :: String.t()
  def gas(),  do: Application.get_env(:ex_plasma, :gas)

  @spec standard_exit_bond_size() :: String.t()
  def standard_exit_bond_size(),  do: Application.get_env(:ex_plasma, :standard_exit_bond_size)
end
