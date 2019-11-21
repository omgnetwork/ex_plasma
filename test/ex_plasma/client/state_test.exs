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

  test "authority/0 returns the authority address" do
    use_cassette "authority", match_requests_on: [:request_body] do
      "0x" <> address = authority_address()
      assert State.authority() == address
    end
  end

  test "get_block/1 returns a block struct" do
    use_cassette "get_block", match_requests_on: [:request_body] do
      %ExPlasma.Block{hash: hash, timestamp: timestamp} = State.get_block(0)

      assert hash ==
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>

      assert timestamp == 0
    end
  end

  test "get_exit_game_address/1 returns an address" do
    use_cassette "get_exit_game_address", match_requests_on: [:request_body] do
      exit_game_address = State.get_exit_game_address(1)

      assert exit_game_address ==
               <<144, 39, 25, 241, 146, 170, 82, 64, 99, 47, 112, 74, 167, 169, 75, 171, 97, 184,
                 101, 80>>
    end
  end

  test "next_child_block/9 returns the next child block to be mined" do
    use_cassette "next_child_block", match_requests_on: [:request_body] do
      assert State.next_child_block() == 1000
    end
  end

  test "child_block_interval/0 returns the block number increment" do
    use_cassette "child_block_interval", match_requests_on: [:request_body] do
      assert State.child_block_interval() == 1000
    end
  end

  test "next_deposit_block/0 returns the next deposit block to be mined" do
    use_cassette "next_deposit_block", match_requests_on: [:request_body] do
      assert State.next_deposit_block() == 1
    end
  end

  test "has_exit_queue/2 returns if an exit queue exists" do
    use_cassette "has_exit_queue", match_requests_on: [:request_body] do
      # NB: Exit Queue has not been added by default after migration
      assert false == State.has_exit_queue(1, <<0::160>>)
    end
  end
end
