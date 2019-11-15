defmodule ExPlasma.Client.Event do
  @moduledoc """
  Grabs contract events.
  """

  import ExPlasma.Client.Config, only: [contract_address: 0, eth_vault_address: 0]
  import ExPlasma.Encoding, only: [to_hex: 1, keccak_hash: 1]

  @doc """
  Get blocks submitted for a specific range.
  """
  def blocks_submitted(from: from, to: to) do
    signature = "BlockSubmitted(uint256)"
    get_events(signature, contract_address(), from, to)
  end

  @doc """
  Return deposit created events for a specific range.
  """
  def deposits(:eth, from: from, to: to) do
    signature = "DepositCreated(address,uint256,address,uint256)"
    get_events(signature, eth_vault_address(), from, to)
  end

  @doc """
  Return deposit created events for a specific range.
  """
  def exit_queues_added(from: from, to: to) do
    signature = "ExitQueueAdded(uint256,address)"
    get_events(signature, contract_address(), from, to)
  end

  defp get_events(signature, contract, from, to) do
    encoded_topic = encode_event_topic_signature(signature)

    Ethereumex.HttpClient.eth_get_logs(%{
      fromBlock: to_hex(from),
      toBlock: to_hex(to),
      address: contract,
      topics: [encoded_topic]
    })
  end

  @spec encode_event_topic_signature(String.t()) :: String.t()
  defp encode_event_topic_signature(signature) do
    signature
    |> keccak_hash()
    |> to_hex()
  end
end
