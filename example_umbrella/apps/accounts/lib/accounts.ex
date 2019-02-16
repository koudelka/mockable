defmodule Accounts do
  use Mockable

  alias Shared.Account

  @type id :: String.t()
  @type account :: {:account, id}

  @spec find(id) :: {:ok, account}
  def find(id) when is_binary(id) do
    {:ok, %Account{address: "some@address.com"}}
  end
end
