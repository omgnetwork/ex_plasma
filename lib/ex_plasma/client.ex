defmodule ExPlasma.Client do
  @moduledoc """
  This module provides functions to talk to the
  contract directly.
  """

  alias ExPlasma.Block
  alias ExPlasma.Transaction

  import ExPlasma,
    only: [
      authority_address: 0,
      contract_address: 0,
      eth_vault_address: 0,
      exit_game_address: 0,
      gas: 0,
      standard_exit_bond_size: 0
    ]

  import ExPlasma.Encoding, only: [to_binary: 1, to_hex: 1]

  @doc """
  Returns the authority address.

  ## Example

    iex> ExPlasma.Client.get_authority()
    "ffcf8fdee72ac11b5c542428b35eef5769c409f0"
  """
  @spec get_authority() :: String.t() | tuple()
  def get_authority() do
    eth_call("authority()", [], fn resp ->
      resp
      |> decode_response([:address])
      |> List.first()
      |> Base.encode16(case: :lower)
    end)
  end

  @doc """
  Returns a `ExPlasma.Block` for the given block number.

  ## Example

    iex> ExPlasma.Client.get_block(0)
    %ExPlasma.Block{
      hash: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      timestamp: 0
    }
  """
  @spec get_block(non_neg_integer()) :: Block.t()
  def get_block(blknum) do
    eth_call("blocks(uint256)", [blknum], fn resp ->
      [merkle_root_hash, timestamp] = decode_response(resp, [{:bytes, 32}, {:uint, 256}])
      %Block{hash: merkle_root_hash, timestamp: timestamp}
    end)
  end

  # TODO achiurizo
  # should there be a consolidated method to:
  # * get the block number from this contract call
  # * then call get_block to return the block struct of it?
  #
  @doc """
  Returns the next child block to be mined.

  ## Example

    iex> ExPlasma.Client.get_next_child_block()
    1000
  """
  @spec get_next_child_block() :: non_neg_integer()
  def get_next_child_block() do
    eth_call("nextChildBlock()", [], fn resp ->
      List.first(decode_response(resp, [{:uint, 256}]))
    end)
  end

  @doc """
  Returns the child block interval, which controls the incrementing
  block number for each child block.

  ## Examples

    iex> ExPlasma.Client.get_child_block_interval()
    1000
  """
  @spec get_child_block_interval() :: non_neg_integer()
  def get_child_block_interval() do
    eth_call("childBlockInterval()", [], fn resp ->
      List.first(decode_response(resp, [{:uint, 256}]))
    end)
  end

  @doc """
  Returns the existing standard exit for the given exit id. The exit id is connected
  to a specific UTXO existing in the contract.
  """
  def get_standard_exit(exit_id) do
    types = [:bool, {:uint, 192}, {:bytes, 32}, :address, {:uint, 256}, {:uint, 256}]

    eth_call("standardExits(uint160)", [exit_id], fn resp ->
      List.first(decode_response(resp, types))
    end)
  end

  @doc """
  Returns the next deposit block to be mined.

  ## Examples

    iex> ExPlasma.Client.get_next_deposit_block()
    1
  """
  @spec get_next_deposit_block() :: non_neg_integer()
  def get_next_deposit_block() do
    eth_call("nextDepositBlock()", [], fn resp ->
      List.first(decode_response(resp, [{:uint, 256}]))
    end)
  end

  @doc """
  Returns whether the exit queue has been added for a given vault_id and token.
  """
  @spec has_exit_queue(non_neg_integer(), String.t()) :: boolean()
  def has_exit_queue(vault_id, token_address) do
    eth_call("hasExitQueue(uint256,address)", [vault_id, token_address], fn resp ->
      [result] = decode_response(resp, [:bool])
      result
    end)
  end

  @spec deposit(ExPlasma.Transactions.Deposit.t(), atom()) :: tuple()
  def deposit(%ExPlasma.Transactions.Deposit{outputs: [output]} = transaction, :eth) do
    transaction
    |> Transaction.encode()
    |> deposit(output[:amount], output[:owner], :eth)
  end

  @spec deposit(binary(), non_neg_integer(), String.t(), String.t()) :: tuple()
  def deposit(tx_bytes, value, from, :eth),
    do: deposit(tx_bytes, value, from, eth_vault_address())

  def deposit(tx_bytes, value, from, to) do
    data = encode_data("deposit(bytes)", [tx_bytes])

    eth_send_transaction(%{
      data: data,
      from: from,
      to: to, 
      value: value
    })
  end

  @doc """
  Submits a block to the contract.
  """
  @spec submit_block(ExPlasma.Block.t()) :: tuple()
  def submit_block(%ExPlasma.Block{hash: hash}) do
    data = encode_data("submitBlock(bytes32)", [hash])
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
      data: data,
    })
  end

  @doc """
  Adds an exit queue for the given vault and token address.
  """
  def add_exit_queue(vault_id, token_address) do
    data = encode_data("addExitQueue(uint256,address)", [vault_id, token_address])
    eth_send_transaction(%{data: data})
  end

  @spec eth_call(String.t(), list(), fun()) :: tuple()
  defp eth_call(contract_signature, data_types, callback) when is_list(data_types) do
    options = %{data: encode_data(contract_signature, data_types), to: contract_address()}

    case Ethereumex.HttpClient.eth_call(options) do
      {:ok, resp} -> callback.(resp)
      other -> other
    end
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
    txmap = %{txmap | gas: to_hex(txmap[:gas]), value: to_hex(txmap[:value]) }

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

  @spec decode_response(String.t(), list()) :: list()
  defp decode_response("0x" <> unprefixed_hash_response, types) do
    unprefixed_hash_response
    |> Base.decode16!(case: :lower)
    |> ABI.TypeDecoder.decode_raw(types)
  end
end
