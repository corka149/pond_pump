defmodule PondPump.PowerCheckTest do
  use ExUnit.Case

  test "incoming power changes triggers light" do
    :ok = Application.ensure_started(:pond_pump)

    # ===== Arrange =====
    message = "Could not open port. Did you compile dependencies with CIRCUITS_MIX_ENV=test?"
    assert %{name: :stub, pins_open: 2} = Circuits.GPIO.info(), message

    # Used for stubbing (even = out, uneven = input)
    {:ok, power_out_gpio} = Circuits.GPIO.open(18, :output)
    {:ok, light_gpio} = Circuits.GPIO.open(27, :input)

    # ===== TURN ON =====
    # ===== Act =====
    # Trigger power check
    Circuits.GPIO.write(power_out_gpio, 1)

    # ===== Assert =====

    # GPIO needs some time
    Process.sleep(2000)

    assert Circuits.GPIO.read(light_gpio) == 1,
           "Light was not turned on"

    # ===== TURN OFF =====
    # ===== Act =====
    # Trigger power check
    Circuits.GPIO.write(power_out_gpio, 0)

    # ===== Assert =====

    # GPIO needs some time
    Process.sleep(2000)

    assert Circuits.GPIO.read(light_gpio) == 0,
           "Light should be turned off"
  end
end
