defmodule ExPlasma.TransactionTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction
  doctest ExPlasma.Transaction.Input
  doctest ExPlasma.Transaction.Output

  alias ExPlasma.Transaction

  test "to_list/1 includes the signatures for a transaction" do
    list =
      %Transaction{
        sigs: ["0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1"]
      }
      |> Transaction.to_list()

    assert list == [
             ["0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1"],
             0,
             [],
             [],
             <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
           ]
  end
end
