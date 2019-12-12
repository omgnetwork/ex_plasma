defmodule Integration.StandardExittest do
  @moduledoc """
  Integration tests for the full standard exit flows.
  """

  use ExUnit.Case

  alias ExPlasma.Block
  alias ExPlasma.Client
  alias ExPlasma.Client.Event
  alias ExPlasma.Transaction
  alias ExPlasma.Utxo
  alias ExPlasma.Transactions.Deposit
  alias ExPlasma.Transactions.Payment

  import ExPlasma.Client.Config,
    only: [authority_address: 0]

  @moduletag :integration

  @private_key "0x6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c"

  test "should be able to standard exit on a valid transaction" do
    utxo = deposit(from: authority_address(), amount: 1)
    exitable_utxo = deposit(from: authority_address(), amount: 1)

    %{tx_bytes: tx_bytes, utxo_pos: utxo_pos, proof: proof} = 
      transact(to: authority_address(), from: authority_address(), utxo: exitable_utxo)


    IO.inspect("---- exit data txbytes-----")
    IO.inspect(tx_bytes, limit: :infinity)
    IO.inspect("---- exit data utxopos-----")
    IO.inspect(utxo_pos, limit: :infinity)
    IO.inspect("---- exit data proof-----")
    IO.inspect(proof, limit: :infinity)

    assert {:ok, _receipt_hash} =
             Client.start_standard_exit(tx_bytes, %{
               from: authority_address(),
               utxo_pos: utxo_pos,
               proof: proof
             })
  end

  # Helper to generate a deposit for the given user and amount.
  #
  # owner - Hex string of the owner address
  # amount - integer amount of how much eth to deposit.
  #
  # Returns the input utxo for the deposit.
  def deposit(from: owner, amount: amount) do
    {:ok, deposit_receipt_hash} = Deposit.new(owner: owner, amount: amount) |> Client.deposit(to: :eth)

    blknum = get_deposits_blknum(deposit_receipt_hash)

    %Utxo{blknum: blknum, txindex: 0, oindex: 0, amount: amount, owner: owner}
  end

  def transact(to: to, from: from, utxo: utxo) do
    output = %{utxo | owner: to} # re-assign the utxo to the new owner, making a new `output`
    payment = Payment.new(%{inputs: [utxo], outputs: [output]})
    #payment = Transaction.sign(payment, keys: [@private_key])
    #
    block = payment |> List.wrap() |> Block.new()

    {:ok, submit_block_hash} = Client.submit_block(block)

    IO.inspect("---- submitting block  block hash----")
    IO.inspect(block.hash, limit: :infinity)
    IO.inspect("submitted block: #{submit_block_hash}")

    blknum = get_blocks_submitted_blknum(submit_block_hash)
    output = %{output | blknum: 13000}

    # We need to rebuild the new input utxo from the output
    # with the current blknum from submission. We also
    # use txindex=0 and oindex=0 since there's only one.
    #{:ok, %{"blockNumber" => "0x" <> blknum}} = Ethereumex.HttpClient.eth_get_transaction_receipt(submit_block_hash)
    #{blknum, ""} = Integer.parse(blknum, 16)
    #output = %{output | blknum: blknum}

    tx_bytes = payment |> Transaction.encode()
    utxo_pos = output |> Utxo.pos()
    proof = ExPlasma.Encoding.merkle_proof([tx_bytes], 0)

    %{tx_bytes: tx_bytes, utxo_pos: utxo_pos, proof: proof}
  end

  def get_blocks_submitted_blknum(receipt_hash) do
    {:ok, current_blknum} = Ethereumex.HttpClient.eth_block_number()
    current_blknum = ExPlasma.Encoding.to_int(current_blknum)
    {:ok, deposit_events} = Client.Event.blocks_submitted(from: current_blknum - 20, to: current_blknum)

    %{"blockNumber" => "0x" <> blknum} =
      deposit_events
      |> Enum.filter(&(__MODULE__.filter_event_by_hash(&1, receipt_hash)))
      |> hd()

    {blknum, ""} = Integer.parse(blknum, 16)
    blknum
  end

  def get_deposits_blknum(receipt_hash) do
    {:ok, current_blknum} = Ethereumex.HttpClient.eth_block_number()
    current_blknum = ExPlasma.Encoding.to_int(current_blknum)
    {:ok, deposit_events} = Client.Event.deposits(:eth, from: current_blknum - 20, to: current_blknum)

    %{"blockNumber" => "0x" <> blknum} =
      deposit_events
      |> Enum.filter(&(__MODULE__.filter_event_by_hash(&1, receipt_hash)))
      |> hd()

    {blknum, ""} = Integer.parse(blknum, 16)
    blknum
  end

  def filter_event_by_hash(%{"transactionHash" => txn_hash}, receipt_hash), do: txn_hash == receipt_hash
end
