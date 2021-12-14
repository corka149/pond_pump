defmodule PondPump.RfReceiver do
  use Task, restart: :permanent

  require Logger

  def start_link([power_pin, receive_pin]) do
    Task.start_link(__MODULE__, :await, [power_pin, receive_pin])
  end

  def await(power_pin, receive_pin) do
    Logger.info("Start listing #{receive_pin}")
    Logger.info("Will turn on light on #{power_pin}")

    power_gpio = setup_power(power_pin)
    receive_gpio = setup_receive(receive_pin)

    do_await(power_gpio, receive_gpio)
  end

  # ===== ===== PRIVATE ===== =====

  defp active_code do
    [1, 1, 1, 0, 0]
  end

  defp do_await(power_gpio, receive_gpio) do
    do_await(power_gpio, receive_gpio)
  end

  defp setup_power(pin) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :output)
    gpio
  end

  defp setup_receive(pin) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :input, initial_value: 0)
    gpio
  end
end
