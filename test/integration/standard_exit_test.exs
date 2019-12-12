defmodule Integration.StandardExittest do
  @moduledoc """
  Integration tests for the full standard exit flows.
  """

  use ExUnit.Case

  alias ExPlasma.Block
  alias ExPlasma.Client
  alias ExPlasma.Transaction
  alias ExPlasma.Transactions.Deposit
  alias ExPlasma.Transactions.Payment
  alias ExPlasma.Utxo

  import ExPlasma.Client.Config,
    only: [authority_address: 0]

  @moduletag :integration

  test "should be able to standard exit on a valid transaction" do
    utxo = deposit(from: authority_address(), amount: 1)

    %{tx_bytes: tx_bytes, utxo_pos: utxo_pos, proof: proof} = 
      transact(to: authority_address(), utxo: utxo)

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
    {:ok, _deposit_receipt_hash} = Deposit.new(owner: owner, amount: amount) |> Client.deposit(to: :eth)

    blknum = get_deposits_blknum()

    %Utxo{blknum: blknum, txindex: 0, oindex: 0, amount: amount, owner: owner}
  end

  # Helper to send an entire utxo to another party.
  #
  # to: - Hex string / binary of the receiver address
  # from: - Hex string / binary of the sender address
  # utxo: - Utxo to use as the input for the output
  #
  # Returns the "exit data" that we can use to standard exit from.
  def transact(to: to, utxo: utxo) do
    output = %{utxo | owner: to}
    payment = Payment.new(%{inputs: [utxo], outputs: [output]})
    block = payment |> List.wrap() |> Block.new()

    {:ok, _submit_block_receipt_hash} = Client.submit_block(block)

    blknum = get_blocks_submitted_blknum()
    output = %{output | blknum: blknum}

    tx_bytes = payment |> Transaction.encode()
    utxo_pos = output |> Utxo.pos()
    proof = ExPlasma.Encoding.merkle_proof([tx_bytes], 0)

    %{tx_bytes: tx_bytes, utxo_pos: utxo_pos, proof: proof}
  end

  # TODO: Leaving this here to figure out how we
  # are suppose to use blknum from the emitted events
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

  def get_blocks_submitted_blknum() do
    next_child_block = ExPlasma.Client.State.next_child_block()
    child_block_interval = ExPlasma.Client.State.child_block_interval()
    next_child_block - child_block_interval
  end

  # Deposit blocks increment by 1 over the current child_block blknum
  def get_deposits_blknum() do
    ExPlasma.Client.State.next_deposit_block - 1
  end

  def filter_event_by_hash(%{"transactionHash" => txn_hash}, receipt_hash), do: txn_hash == receipt_hash
end
