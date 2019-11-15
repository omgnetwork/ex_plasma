defmodule ExPlasma.Client.StateTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias ExPlasma.Client.State

  import ExPlasma.Client.Config,
    only: [authority_address: 0]

  setup do
    Application.ensure_all_started(:ethereumex)
    ExVCR.Config.cassette_library_dir("./test/fixtures/vcr_cassettes/state")
    :ok
  end

  test "get_authority/0 returns the authority address" do
    use_cassette "get_authority", match_requests_on: [:request_body] do
      "0x" <> address = authority_address()
      assert State.get_authority() == address
    end
  end
end
