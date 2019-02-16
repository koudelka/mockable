defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  import Mox

  alias Example.MockAccounts

  setup [:set_mox_from_context, :verify_on_exit!]

  test "when account not found" do
    MockAccounts
    |> expect(:find, fn _ -> {:error, :not_found} end)

    assert {:error, :account_not_found} = Example.send_welcome("abc")
  end
end
