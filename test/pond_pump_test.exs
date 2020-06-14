defmodule PondPumpTest do
  use ExUnit.Case
  doctest PondPump

  test "greets the world" do
    assert PondPump.hello() == :world
  end
end
