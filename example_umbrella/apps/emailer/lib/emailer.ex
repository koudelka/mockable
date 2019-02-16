defmodule Emailer do
  use Mockable

  @type address :: String.t()
  @type body :: String.t()
  @type email :: {:email, address, body}

  @spec send_email(address, body) :: {:ok, email} | {:error, term()}
  def send_email(address, body \\ "hi!")
  def send_email(address, body) when is_binary(address) do
    {:ok, {:email, address, body}}
  end

  def send_email(_address, _body) do
    {:error, :address_invalid}
  end
end
