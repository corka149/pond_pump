defmodule PondPump.PowerCheckTest do
  use ExUnit.Case

  test "incoming power triggers notifcation output" do
    # ===== Arrange =====
    message = "Could not open port. Did you compile dependencies with CIRCUITS_MIX_ENV=test?"
    assert %{name: :stub, pins_open: 0} = Circuits.GPIO.info(), message

    value = 1

    # Used for stubbing (even = out, uneven = input)
    {:ok, power_out_gpio} = Circuits.GPIO.open(18, :output)
    {:ok, light_gpio} = Circuits.GPIO.open(27, :input)

    # ===== Act =====
    # Trigger power check
    Circuits.GPIO.write(power_out_gpio, value)

    # ===== Assert =====

    # GPIO needs some time
    Process.sleep(2000)

    assert Circuits.GPIO.read(light_gpio) == value,
           "Light was not turned on at the end"
  end
end
