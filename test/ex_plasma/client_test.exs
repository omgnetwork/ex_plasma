defmodule ExPlasma.ClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias ExPlasma.Block
  alias ExPlasma.Client
  alias ExPlasma.Transaction
  alias ExPlasma.Utxo
  alias ExPlasma.Transactions.Deposit
  alias ExPlasma.Transactions.Payment

  import ExPlasma.Client.Config,
    only: [authority_address: 0]

  @moduletag :vcr

  setup do
    Application.ensure_all_started(:ethereumex)
    ExVCR.Config.cassette_library_dir("./test/fixtures/vcr_cassettes/client")
    :ok
  end

  describe "deposit/2" do
    test "accepts a keyword list for the options" do
      use_cassette "deposit", match_requests_on: [:request_body] do
        currency = ExPlasma.Encoding.to_hex(<<0::160>>)

        assert {:ok, _receipt_hash} =
                 %Utxo{owner: authority_address(), currency: currency, amount: 1}
                 |> Deposit.new()
                 |> Client.deposit(to: :eth)
      end
    end

    test "sends deposit transaction with a deposit struct" do
      use_cassette "deposit", match_requests_on: [:request_body] do
        currency = ExPlasma.Encoding.to_hex(<<0::160>>)

        assert {:ok, _receipt_hash} =
                 %Utxo{owner: authority_address(), currency: currency, amount: 1}
                 |> Deposit.new()
                 |> Client.deposit(%{to: :eth})
      end
    end

    test "sends deposit tx_bytes into the contract" do
      use_cassette "deposit", match_requests_on: [:request_body] do
        currency = ExPlasma.Encoding.to_hex(<<0::160>>)

        tx_bytes =
          %Utxo{owner: authority_address(), currency: currency, amount: 1}
          |> Deposit.new()
          |> Transaction.encode()

        assert {:ok, _receipt_hash} =
                 Client.deposit(tx_bytes, %{from: authority_address(), to: :eth, value: 1})
      end
    end
  end

  describe "submit_block/3" do
    test "it submits a block of transactions" do
      use_cassette "submit_block", match_requests_on: [:request_body] do
        assert {:ok, _receipt_hash} =
                 Payment.new(%{inputs: [%Utxo{}], outputs: [%Utxo{}]})
                 |> List.wrap()
                 |> Block.new()
                 |> Client.submit_block()
      end
    end
  end

  describe "process_exits/5" do
    test "it processes a standard exit for the owner" do
      use_cassette "process_exits", match_requests_on: [:request_body] do
        assert {:ok, _receipt_hash} =
                 Client.process_exits(0, %{
                   from: authority_address(),
                   vault_id: 1,
                   currency: <<0::160>>,
                   total_exits: 1
                 })
      end
    end
  end

  describe "add_exit_queue/2" do
    test "it adds an exit queue for a given vault id and token address" do
      use_cassette "add_exit_queue", match_requests_on: [:request_body] do
        assert {:ok, _receipt_hash} = Client.add_exit_queue(1, <<0::160>>)
      end
    end
  end
end
