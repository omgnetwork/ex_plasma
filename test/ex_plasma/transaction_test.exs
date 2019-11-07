defmodule ExPlasma.TransactionTest do
  use ExUnit.Case, async: true
  doctest ExPlasma.Transaction
  doctest ExPlasma.Transaction.Input
  doctest ExPlasma.Transaction.Output

  alias ExPlasma.Transaction

  test "to_list/1 includes the sigs for a transaction" do
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

  test "encode/1 will encode a transaction with sigs" do
    encoded =
      %Transaction{
        sigs: ["0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1"]
      }
      |> Transaction.encode()

    assert encoded ==
             <<248, 94, 248, 68, 184, 66, 48, 120, 54, 99, 98, 101, 100, 49, 53, 99, 55, 57, 51,
               99, 101, 53, 55, 54, 53, 48, 98, 57, 56, 55, 55, 99, 102, 54, 102, 97, 49, 53, 54,
               102, 98, 101, 102, 53, 49, 51, 99, 52, 101, 54, 49, 51, 52, 102, 48, 50, 50, 97,
               56, 53, 98, 49, 102, 102, 100, 100, 53, 57, 98, 50, 97, 49, 128, 192, 192, 148, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  end
end
