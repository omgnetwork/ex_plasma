defmodule ExPlasma.ClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias ExPlasma.Block
  alias ExPlasma.Client
  alias ExPlasma.Transaction
  alias ExPlasma.Transaction.Input
  alias ExPlasma.Transaction.Output
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
      metadata = ExPlasma.Encoding.to_hex(<<0::256>>)
      deposit = Deposit.new(authority_address(), currency, 1, metadata)

      assert {:ok, _receipt_hash} = Client.deposit(deposit, :eth)
    end
  end

  test "deposit/4 sends deposit transaction into the contract" do
    # TODO fix the amount passing to match value/sent amount
    use_cassette "deposit", match_requests_on: [:request_body] do
      # NB: Contracts currently sets 'eth' to a zero address.
      currency = ExPlasma.Encoding.to_hex(<<0::160>>)
      # TODO: We need to do something about this 0 bytes thing
      metadata = ExPlasma.Encoding.to_hex(<<0::256>>)
      deposit = Deposit.new(authority_address(), currency, 1, metadata)

      assert {:ok, _receipt_hash} =
               deposit
               |> Transaction.encode()
               # TODO fix this ish to pick up from deposit
               |> Client.deposit(1, authority_address(), :eth)
    end
  end

  describe "submit_block/3" do
    test "it submits a block of transactions" do
      use_cassette "submit_block", match_requests_on: [:request_body] do
        authority = "0x22d491bde2303f2f43325b2108d26f1eaba1e32b"
        currency = "0x2e262d291c2E969fB0849d99D9Ce41e2F137006e"
        amount = 1
        metadata = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"
        output = %Output{owner: authority, currency: currency, amount: amount}
        input = %Input{}
        transaction = Payment.new(inputs: [input], outputs: [output], metadata: metadata)

        assert {:ok, _receipt_hash} =
                 Block.new([transaction])
                 |> Client.submit_block()
      end
    end
  end

  @tag :solo
  describe "start_standard_exit/3" do
    test "it starts a standard exit for the owner" do
      #use_cassette "start_standard_exit", match_requests_on: [:request_body] do
         currency = ExPlasma.Encoding.to_hex(<<0::160>>)
         metadata = ExPlasma.Encoding.to_hex(<<0::256>>)
         deposit = Deposit.new(authority_address(), currency, 1, metadata)
         #%ExPlasma.Block{hash: txbytes} = ExPlasma.Block.new([deposit])

        txbytes = deposit |> Transaction.encode() |> ExPlasma.Encoding.to_hex()
        utxo_pos = 5_023_000_000_000

        #txbytes = "0xf85901c0f5f4019469d162b209e5bb6858e8f0ae7a651995fe166236940000000000000000000000000000000000000000880de0b6b3a7640000a00000000000000000000000000000000000000000000000000000000000000000"

        proof = ExPlasma.Encoding.merkle_proof([txbytes], 1)

         #proof ="0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8ecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2dadefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eeade1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e107ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82e026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e836365163d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409cad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203ea2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c8622def10d13dd169f550f578bda343d9717a138562e0093b3"

        assert {:ok, _receipt_hash} =
                 Client.start_standard_exit(authority_address(), utxo_pos, txbytes, proof)
      #end
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
