defmodule ExPlasma.Client.State do
  @moduledoc """
  Module to fetch all the contract configurations and current 'state' available.
  """

  import ExPlasma.Client.Config,
    only: [
      authority_address: 0,
      contract_address: 0,
      eth_vault_address: 0,
      exit_game_address: 0,
      gas: 0,
      standard_exit_bond_size: 0
    ]

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

  @spec eth_call(String.t(), list(), fun()) :: tuple()
  defp eth_call(contract_signature, data_types, callback) when is_list(data_types) do
    options = %{data: encode_data(contract_signature, data_types), to: contract_address()}

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
