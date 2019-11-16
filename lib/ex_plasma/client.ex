defmodule ExPlasma.Client do
  @moduledoc """
  This module provides functions to talk to the
  contract directly.
  """

  alias ExPlasma.Transaction

  import ExPlasma.Client.Config,
    only: [
      authority_address: 0,
      contract_address: 0,
      eth_vault_address: 0,
      exit_game_address: 0,
      gas: 0,
      standard_exit_bond_size: 0
    ]

  import ExPlasma.Encoding, only: [to_hex: 1]

  @spec deposit(ExPlasma.Transactions.Deposit.t(), atom()) :: tuple()
  def deposit(%ExPlasma.Transactions.Deposit{outputs: [output]} = transaction, :eth) do
    transaction
    |> Transaction.encode()
    |> deposit(output.amount, output.owner, :eth)
  end

  @spec deposit(binary(), non_neg_integer(), String.t(), String.t()) :: tuple()
  def deposit(tx_bytes, value, from, :eth),
    do: deposit(tx_bytes, value, from, eth_vault_address())

  def deposit(tx_bytes, value, from, to) do
    data = encode_data("deposit(bytes)", [tx_bytes])
    eth_send_transaction(%{data: data, from: from, to: to, value: value})
  end

  @doc """
  Submits a block to the contract.
  """
  @spec submit_block(ExPlasma.Block.t()) :: tuple()
  def submit_block(%ExPlasma.Block{hash: block_hash}), do: submit_block(block_hash)

  @spec submit_block(String.t()) :: tuple()
  def submit_block(block_hash) do
    data = encode_data("submitBlock(bytes32)", [block_hash])
    eth_send_transaction(%{data: data, value: 0})
  end

  @doc """
  Start a Standard Exit

    * owner    - Who's starting the standard exit.
    * utxo_pos - The position of the utxo.
    * txybtes  - The encoded hash of the transaction that created the utxo.
    * proof    - The merkle proof.
    * outputGuardPreImage - TODO
  """
  def start_standard_exit(owner, utxo_pos, txbyte, proof, outputGuardPreImage \\ "") do
    data =
      encode_data(
        "startStandardExit((uint256,bytes,bytes,bytes))",
        [{utxo_pos, txbyte, outputGuardPreImage, proof}]
      )

    eth_send_transaction(%{
      from: owner,
      to: exit_game_address(),
      value: standard_exit_bond_size(),
      data: data
    })
  end

  @doc """
  Adds an exit queue for the given vault and token address.
  """
  def add_exit_queue(vault_id, token_address) do
    data = encode_data("addExitQueue(uint256,address)", [vault_id, token_address])
    eth_send_transaction(%{data: data})
  end

  @spec eth_send_transaction(map()) :: tuple()
  defp eth_send_transaction(%{} = options) do
    default_options = %{
      from: authority_address(),
      to: contract_address(),
      gas: gas(),
      value: 0
    }

    txmap = Map.merge(default_options, options)
    txmap = %{txmap | gas: to_hex(txmap[:gas]), value: to_hex(txmap[:value])}

    case Ethereumex.HttpClient.eth_send_transaction(txmap) do
      {:ok, receipt_enc} -> {:ok, receipt_enc}
      other -> other
    end
  end

  @spec encode_data(String.t(), list()) :: binary
  defp encode_data(function_signature, data) do
    data = ABI.encode(function_signature, data)
    "0x" <> Base.encode16(data, case: :lower)
  end
end
