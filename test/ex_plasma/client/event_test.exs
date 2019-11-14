defmodule ExPlasma.Client.EventTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias ExPlasma.Client.Event

  setup do
    Application.ensure_all_started(:ethereumex)
    ExVCR.Config.cassette_library_dir("./test/fixtures/vcr_cassettes/event")
    :ok
  end

  test "blocks_submitted/2 retuns block submitted events for a range" do
    use_cassette "blocks_submitted", match_requests_on: [:request_body] do
      assert {:ok, results} = Event.blocks_submitted(from: 0, to: 1000)

      event = hd(results)
      assert is_map(event)
    end
  end

  describe "deposits/3" do
    test "it returns events for eth deposits" do
      use_cassette "deposits", match_requests_on: [:request_body] do
        assert {:ok, results} =
          Event.deposits(:eth, from: 0, to: 1000)

        event = hd(results)
        assert is_map(event)
      end
    end
  end
end
