# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ex_plasma,
  authority_address: "0x22d491bde2303f2f43325b2108d26f1eaba1e32b",
  contract_address: "0xd17e1233a03affb9092d5109179b43d6a8828607",
  eth_vault_address: "0x1967d06b1faba91eaadb1be33b277447ea24fa0e",
  exit_game_address: "0xf2507a7ed2c706e64c3e84acb552ee71bc9522d4",
  gas: 1_000_000,
  gas_price: 1_000_000,
  standard_exit_bond_size: 14_000_000_000_000_000,
  eip_712_domain: [
    name: "OMG Network",
    salt: "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
    verifying_contract: "0xd17e1233a03affb9092d5109179b43d6a8828607",
    version: "1"
  ]

config :ethereumex,
  id_reset: true,
  url: "http://localhost:8545"

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :ex_plasma, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:ex_plasma, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"
