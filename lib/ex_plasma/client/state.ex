defmodule ExPlasma.Client.State do
  @moduledoc """
  Module to fetch all the contract configurations and current 'state' available.
  """

  alias ExPlasma.Block

  import ExPlasma.Client.Config,
    only: [
      contract_address: 0,
      exit_game_address: 0
    ]

  @doc """
  Returns the authority address.

  ## Example

    iex> ExPlasma.Client.authority()
    "ffcf8fdee72ac11b5c542428b35eef5769c409f0"
  """
  @spec authority() :: String.t() | tuple()
  def authority() do
    eth_call("authority()", [], fn resp ->
      resp |> decode_response([:address]) |> hd()
    end)
  end

  @doc """
  Returns the next child block to be mined.
  """
  @spec next_child_block() :: non_neg_integer() | tuple()
  def next_child_block() do
    eth_call("nextChildBlock()", [], fn resp ->
      resp |> decode_response([{:uint, 256}]) |> hd()
    end)
  end

  @doc """
  Returns the child block interval, which controls the incrementing
  block number for each child block.
  """
  @spec child_block_interval() :: non_neg_integer() | tuple()
  def child_block_interval() do
    eth_call("childBlockInterval()", [], fn resp ->
      resp |> decode_response([{:uint, 256}]) |> hd()
    end)
  end

  @doc """
  Returns a `ExPlasma.Block` for the given block number.
  """
  @spec get_block(pos_integer()) :: Block.t() | tuple()
  def get_block(blknum) when is_integer(blknum) do
    eth_call("blocks(uint256)", [blknum], fn resp ->
      [merkle_root_hash, timestamp] = decode_response(resp, [{:bytes, 32}, {:uint, 256}])
      %Block{hash: merkle_root_hash, timestamp: timestamp}
    end)
  end

  @doc """
  Returns the exit game address for the given transaction type id.
  """
  def get_exit_game_address(txn_type_id) when is_integer(txn_type_id) do
    eth_call("exitGames(uint256)", [txn_type_id], fn resp ->
      resp |> decode_response([:address]) |> hd()
    end)
  end

  def standard_exit_bond_size() do
    eth_call("startStandardExitBondSize()", [], [to: exit_game_address()], fn resp ->
      resp |> decode_response([{:uint, 128}]) |> hd()
    end)
  end

  @doc """
  Returns the existing standard exit for the given exit id. The exit id is connected
  to a specific UTXO existing in the contract.
  """
  def standard_exits(exit_id) do
    types = [:bool, {:uint, 192}, {:bytes, 32}, :address, {:uint, 256}, {:uint, 256}]

    eth_call("standardExits(uint160)", [exit_id], fn resp ->
      List.first(decode_response(resp, types))
    end)
  end

  @doc """
  Returns the exit id for the given tx_bytes and utxo_pos.
  """
  def get_standard_exit_id(is_deposit, tx_bytes, utxo_pos) do
    eth_call(
      "getStandardExitId(bool,bytes,uint256)",
      [is_deposit, tx_bytes, utxo_pos],
      [to: exit_game_address()],
      fn resp ->
        resp |> decode_response([{:uint, 160}]) |> hd()
      end
    )
  end

  @doc """
  Returns the next deposit block to be mined.

  ## Examples

    iex> ExPlasma.Client.next_deposit_block()
    1
  """
  @spec next_deposit_block() :: tuple() | non_neg_integer()
  def next_deposit_block() do
    eth_call("nextDepositBlock()", [], fn resp ->
      resp |> decode_response([{:uint, 256}]) |> hd()
    end)
  end

  @doc """
  Returns whether the exit queue has been added for a given vault_id and token.
  """
  @spec has_exit_queue(non_neg_integer(), String.t()) :: boolean() | tuple()
  def has_exit_queue(vault_id, token_address) do
    eth_call("hasExitQueue(uint256,address)", [vault_id, token_address], fn resp ->
      [result] = decode_response(resp, [:bool])
      result
    end)
  end

  @spec eth_call(String.t(), list(), fun()) :: tuple()
  defp eth_call(contract_signature, data_types, state \\ [to: nil], callback)

  defp eth_call(contract_signature, data_types, [to: to], callback) when is_list(data_types) do
    to = to || contract_address()
    options = %{data: encode_data(contract_signature, data_types), to: to}

    case Ethereumex.HttpClient.eth_call(options) do
      {:ok, resp} -> callback.(resp)
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
