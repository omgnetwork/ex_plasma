defmodule ExPlasma.ClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias ExPlasma.Client

  setup do
    Application.ensure_all_started(:ethereumex)
    ExVCR.Config.cassette_library_dir("./test/fixtures/vcr_cassettes")
    # NOTE achiurizo
    #
    # this is a hack to ensure we reset the counter to 0 despite
    # the fixtures now resetting the counter.
    :ets.insert(:rpc_requests_counter, {:rpc_counter, 0})
    :ok
  end

  test "get_operator/0 returns the operator address" do
    use_cassette "get_operator", match_requests_on: [:request_body] do
      assert Client.get_operator() == "ffcf8fdee72ac11b5c542428b35eef5769c409f0"
    end
  end

  test "get_block/1 returns a block struct" do
    use_cassette "get_block", match_requests_on: [:request_body] do
      %ExPlasma.Block{hash: hash, timestamp: timestamp} = Client.get_block(0)

      assert hash ==
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0>>

      assert timestamp == 0
    end
  end

  test "get_next_child_block/9 returns the next child block to be mined" do
    use_cassette "get_next_child_block", match_requests_on: [:request_body] do
      assert Client.get_next_child_block() == 1000
    end
  end

  test "get_child_block_interval/0 returns the block number increment" do
    use_cassette "get_child_block_interval", match_requests_on: [:request_body] do
      assert Client.get_child_block_interval() == 1000
    end
  end

  test "get_next_deposit_block/0 returns the next deposit block to be mined" do
    use_cassette "get_next_deposit_block", match_requests_on: [:request_body] do
      assert Client.get_next_deposit_block() == 1
    end
  end
end
