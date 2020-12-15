defmodule Conformance.InFlightExitTest do
  @moduledoc """
  Conformance tests that check our local in-flight exit implementation aligns with the plasma contracts.
  """
  use ExUnit.Case, async: true
  alias ExPlasma.InFlightExit

  @moduletag :conformance

  # The address where ExitIDWrapper is deployed. Ganache keeps this deterministic..
  @contract "0x32cf1f3a98aeaf57b88b3740875d19912a522c1a"

  @ife_tx_hexes [
    "0x",
    "0x1234",
    "0xb26f143eb9e68e5b",
    "0x70de28d3cd1cb609",
    "0xc235a61a575eb3e2",
    "0x8fdeb13e6acdc74955fdcf0f345ae57a",
    "0x00000000000000000000000000000000",
    "0xffffffffffffffffffffffffffffffff"
  ]

  describe "tx_bytes_to_id/1" do
    test "matches PaymentExitGame.getInFlightExitId(bytes)" do
      Enum.each(@ife_tx_hexes, fn hex ->
        tx_bytes = ExPlasma.Encoding.to_binary!(hex)
        assert InFlightExit.tx_bytes_to_id(tx_bytes) == contract_get_in_flight_exit_id(tx_bytes)
      end)
    end
  end

  defp contract_get_in_flight_exit_id(tx_bytes) do
    eth_call("getInFlightExitId(bytes)", [tx_bytes], [to: @contract], fn resp ->
      resp |> decode_response([{:uint, 168}]) |> hd()
    end)
  end

  defp eth_call(contract_signature, data, [to: to], callback) when is_list(data) do
    options = %{data: encode_data(contract_signature, data), to: to}

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
