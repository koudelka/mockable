defmodule MockableTest do
  use ExUnit.Case
  doctest Mockable

  test "greets the world" do
    assert Mockable.hello() == :world
  end
end
