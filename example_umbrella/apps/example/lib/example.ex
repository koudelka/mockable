defmodule Example do
  alias Shared.Account

  def send_welcome(account_id) do
    with {:ok, %Account{address: address}} <- Accounts.find(account_id),
         {:ok, _email} <- Emailer.send_email(address, "welcome") do
      :ok
    else
      {:error, :not_found} ->
        {:error, :account_not_found}
      {:error, :address_invalid} ->
        {:error, :address_invalid}
    end
  end
end
