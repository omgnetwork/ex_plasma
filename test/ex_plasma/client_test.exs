defmodule ExPlasma.ClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias ExPlasma.Block
  alias ExPlasma.Client
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Utxo
  alias ExPlasma.Transactions.Deposit
  alias ExPlasma.Transactions.Payment

  import ExPlasma.Client.Config,
    only: [authority_address: 0]

  setup do
    Application.ensure_all_started(:ethereumex)
    ExVCR.Config.cassette_library_dir("./test/fixtures/vcr_cassettes/client")
    :ok
  end

  test "deposit/1 sends deposit transaction with the struct" do
    use_cassette "deposit", match_requests_on: [:request_body] do
      currency = ExPlasma.Encoding.to_hex(<<0::160>>)

      assert {:ok, _receipt_hash} =
               %Utxo{owner: authority_address(), currency: currency, amount: 1}
               |> Deposit.new()
               |> Client.deposit(%{to: :eth})
    end
  end

  test "deposit/4 sends deposit transaction into the contract" do
    use_cassette "deposit", match_requests_on: [:request_body] do
      currency = ExPlasma.Encoding.to_hex(<<0::160>>)
      tx_bytes = %Utxo{owner: authority_address(), currency: currency, amount: 1}
               |> Deposit.new()
               |> Transaction.encode()

      assert {:ok, _receipt_hash} = Client.deposit(tx_bytes, %{from: authority_address(), to: :eth, value: 1})
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

  describe "start_standard_exit/3" do
    test "it starts a standard exit for the owner" do
      use_cassette "start_standard_exit", match_requests_on: [:request_body] do
        currency = ExPlasma.Encoding.to_hex(<<0::160>>)
        utxo = %Utxo{owner: authority_address(), currency: currency, amount: 1}
        deposit = Deposit.new(utxo)
        tx_bytes = deposit |> Transaction.encode() |> ExPlasma.Encoding.to_hex()
        utxo_pos = 5_023_000_000_000
        proof = ExPlasma.Encoding.merkle_proof([tx_bytes], 1)

        assert {:ok, _receipt_hash} =
                 Client.start_standard_exit(tx_bytes, %{from: authority_address(), utxo_pos: utxo_pos, proof: proof})
      end
    end
  end

  describe "process_exits/5" do
    test "it processes a standard exit for the owner" do
      use_cassette "process_exits", match_requests_on: [:request_body] do
        assert {:ok, _receipt_hash} =
                 Client.process_exits(0, %{from: authority_address(), vault_id: 1, currency: <<0::160>>, total_exits: 1})
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
