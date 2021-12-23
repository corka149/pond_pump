defmodule PondPump.PowerSignal do
  use Task, restart: :permanent

  require Logger

  def start_link([light_pin]) do
    Task.start_link(__MODULE__, :await, [light_pin])
  end

  def await(light_pin) do
    power_gpio = setup_power(light_pin)

    # TODO
  end

  # ===== ===== PRIVATE ===== =====

  defp setup_power(pin) do
    Logger.info("Will turn on light on #{pin}")
    {:ok, gpio} = Circuits.GPIO.open(pin, :output)
    gpio
  end
end
