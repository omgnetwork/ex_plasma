defmodule ExPlasma.ClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias ExPlasma.Client
  alias ExPlasma.Transactions.Deposit

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

  test "deposit/4 sends deposit transaction into the contract" do
    # TODO fix the amount passing to match value/sent amount
    use_cassette "deposit", match_requests_on: [:request_body] do
      contract = "0x1967d06b1faba91eaadb1be33b277447ea24fa0e"
      alice = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
      # NB: Contracts currently sets 'eth' to a zero address.
      currency = ExPlasma.Encoding.to_hex(<<0::160>>)
      # TODO: We need to do something about this 0 bytes thing
      metadata = ExPlasma.Encoding.to_hex(<<0::256>>)
      deposit = Deposit.new(alice, currency, 1, metadata)

      assert {:ok, _receipt_hash} =
               deposit
               |> Deposit.encode()
               # TODO fix this ish to pick up from deposit
               |> Client.deposit(alice, contract, 1)
    end
  end
end
