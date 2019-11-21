defmodule ExPlasma.Client.StateTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias ExPlasma.Client.State

  setup do
    Application.ensure_all_started(:ethereumex)
    ExVCR.Config.cassette_library_dir("./test/fixtures/vcr_cassettes/state")
    :ok
  end

  test "authority/0 returns the authority address" do
    use_cassette "authority", match_requests_on: [:request_body] do
      assert State.authority() ==
               <<34, 212, 145, 189, 226, 48, 63, 47, 67, 50, 91, 33, 8, 210, 111, 30, 171, 161,
                 227, 43>>
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

  test "standard_exit_bond_size/0 returns an integer bond size" do
    use_cassette "standard_exit_bond_size", match_requests_on: [:request_body] do
      standard_exit_bond_size = State.standard_exit_bond_size()

      assert standard_exit_bond_size == 14_000_000_000_000_000
    end
  end

  test "get_standard_exit_id/3 returns an exit id as uint160" do
    use_cassette "get_standard_exit_id", match_requests_on: [:request_body] do
      standard_exit_id =
        State.get_standard_exit_id(
          true,
          ExPlasma.Encoding.to_binary(
            "0xf85901c0f5f40194c817898296b27589230b891f144dd71a892b0c18940000000000000000000000000000000000000000880de0b6b3a7640000a00000000000000000000000000000000000000000000000000000000000000000"
          ),
          13_000_000_000
        )

      assert standard_exit_id ==
               1_781_569_376_013_285_581_529_144_574_075_905_971_817_810_818
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
