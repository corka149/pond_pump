defmodule PondPump.PowerCheckTest do
  use ExUnit.Case

  test "incoming power triggers notifcation output" do
    # ===== Arrange =====
    message = "Could not open port. Did you compile dependencies with CIRCUITS_MIX_ENV=test?"
    assert {:ok, _gpio} = Circuits.GPIO.open(0, :output), message

    value = 1

    # Used for stubbing
    {:ok, power_check_gpio} = Circuits.GPIO.open(20, :output)
    {:ok, notification_check_gpio} = Circuits.GPIO.open(31, :input)

    # ===== Act =====
    # Trigger power check
    Circuits.GPIO.write(power_check_gpio, value)

    # ===== Assert =====

    # GPIO needs some time
    Process.sleep(2000)

    assert Circuits.GPIO.read(notification_check_gpio) == value,
           "Output was not turned on at the end"
  end
end
