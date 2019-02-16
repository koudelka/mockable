defmodule Shared.Account do
  defstruct [:address]

  @type address :: String.t()

  @type t :: %__MODULE__{
    address: address
  }
end
