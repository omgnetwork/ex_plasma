defmodule ExPlasma.Client do
  @moduledoc """
  This module provides functions to talk to the
  contract directly.
  """

  alias ExPlasma.Transaction
  alias ExPlasma.Transactions.Deposit

  import ExPlasma.Client.Config,
    only: [
      authority_address: 0,
      contract_address: 0,
      eth_vault_address: 0,
      exit_game_address: 0,
      gas: 0,
      gas_price: 0,
      standard_exit_bond_size: 0
    ]

  import ExPlasma.Encoding, only: [to_hex: 1]

  @spec deposit(Deposit.t() | binary()) :: tuple()
  def deposit(tx_bytes, options \\ %{})

  def deposit(%Deposit{outputs: [output]} = transaction, options) do
    options = Map.merge(options, %{from: output.owner, to: :eth, value: output.amount})

    transaction
    |> Transaction.encode()
    |> deposit(options)
  end

  def deposit(tx_bytes, %{to: :eth} = options),
    do: deposit(tx_bytes, %{options | to: eth_vault_address()})

  def deposit(tx_bytes, %{to: to, value: value} = options) do
    data = encode_data("deposit(bytes)", [tx_bytes])
    eth_send_transaction(%{data: data, to: to, value: value}, options)
  end

  @doc """
  Submits a block to the contract.
  """
  @spec submit_block(ExPlasma.Block.t() | String.t(), map()) :: tuple()
  def submit_block(block_hash, options \\ %{})

  def submit_block(%ExPlasma.Block{hash: block_hash}, options),
    do: submit_block(block_hash, options)

  def submit_block(block_hash, options) do
    data = encode_data("submitBlock(bytes32)", [block_hash])
    eth_send_transaction(%{data: data, value: 0}, options)
  end

  @doc """
  Start a Standard Exit

    * owner    - Who's starting the standard exit.
    * utxo_pos - The position of the utxo.
    * tx_bytes  - The encoded hash of the transaction that created the utxo.
    * proof    - The merkle proof.
    * output_guard_pre_image 
  """
  @spec start_standard_exit(binary(), map()) :: tuple()
  def start_standard_exit(tx_bytes, %{utxo_pos: utxo_pos, proof: proof} = options) do
    output_guard_pre_image = options[:output_guard_pre_image] || ""

    data =
      encode_data(
        "startStandardExit((uint256,bytes,bytes,bytes))",
        [{utxo_pos, tx_bytes, output_guard_pre_image, proof}]
      )

    eth_send_transaction(
      %{
        to: exit_game_address(),
        value: standard_exit_bond_size(),
        data: data
      },
      options
    )
  end

  @doc """
  Process exits in Plasma. This will allow you to process your a specific exit or a
  set number of exits. 
  """
  @spec process_exits(non_neg_integer(), map()) :: tuple()
  def process_exits(
        exit_id,
        %{from: from, vault_id: vault_id, currency: currency, total_exits: total_exits} = options
      ) do
    data =
      encode_data(
        "processExits(uint256,address,uint160,uint256)",
        [vault_id, currency, exit_id, total_exits]
      )

    eth_send_transaction(
      %{
        from: from || authority_address(),
        to: contract_address(),
        data: data
      },
      options
    )
  end

  @doc """
  Adds an exit queue for the given vault and token address.
  """
  @spec add_exit_queue(non_neg_integer(), binary(), map()) :: tuple()
  def add_exit_queue(vault_id, token_address, options \\ %{}) do
    data = encode_data("addExitQueue(uint256,address)", [vault_id, token_address])
    eth_send_transaction(%{data: data}, options)
  end

  defp eth_send_transaction(%{} = details, options) do
    txmap = merge_default_options(details, options)

    case Ethereumex.HttpClient.eth_send_transaction(txmap) do
      {:ok, receipt_hash} -> {:ok, receipt_hash}
      other -> other
    end
  end

  defp merge_default_options(details, %{} = options) do
    options = default_options() |> Map.merge(details) |> Map.merge(options)
    %{
      data: options[:data],
      from: options[:from],
      gas: to_hex(options[:gas]),
      gasPrice: to_hex(options[:gasPrice] || options[:gas_price]),
      to: options[:to],
      value: to_hex(options[:value])
    }
  end

  defp default_options() do
    %{
      from: authority_address(),
      gas: gas(),
      gasPrice: gas_price(),
      to: contract_address(),
      value: 0
    }
  end

  @spec encode_data(String.t(), list()) :: binary
  defp encode_data(function_signature, data) do
    data = ABI.encode(function_signature, data)
    "0x" <> Base.encode16(data, case: :lower)
  end
end
