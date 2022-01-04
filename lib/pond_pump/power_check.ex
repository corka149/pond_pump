defmodule PondPump.PowerCheck do
  use Task, restart: :permanent

  require Logger

  def start_link([power_pin]) do
    Task.start_link(__MODULE__, :observe, [power_pin])
  end

  @doc """
  Observes a power pin and sends an "active" message via MQTT.
  """
  @spec observe(non_neg_integer) :: no_return
  def observe(power_pin) do
    Logger.info("Start listing #{power_pin}")

    power_gpio = setup_power(power_pin)

    do_observe(power_gpio)
  end

  # ===== ===== PRIVATE ===== =====

  defp do_observe(power_gpio, last_state \\ :off) do
    last_state =
      receive do
        notification ->
          transmit(notification, last_state)
      after
        5000 ->
          transmit(last_state)
      end

    do_observe(power_gpio, last_state)
  end

  defp transmit({:circuits_gpio, _pin, _timestamp, 1}, _last_state) do
    Logger.info("Power active")
    :ok = Tortoise311.publish(PondPump, pump_topic(), 1)

    :on
  end

  defp transmit({:circuits_gpio, _pin, _timestamp, 0}, _last_state) do
    Logger.info("Power inactive")
    :ok = Tortoise311.publish(PondPump, pump_topic(), 0)

    :off
  end

  defp transmit(unknown_notification, last_state) do
    Logger.warn("Unknown message #{unknown_notification}")
    last_state
  end

  defp transmit(:on) do
    Logger.info("Power still active")
    :on
  end

  defp transmit(:off) do
    Logger.info("Power still inactive")

    :off
  end

  # Setup

  defp setup_power(pin) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :input)

    :ok = Circuits.GPIO.set_interrupts(gpio, :both)

    # https://github.com/raspberrypilearning/physical-computing-guide/blob/master/pull_up_down.md
    :ok = Circuits.GPIO.set_pull_mode(gpio, :pulldown)

    gpio
  end

  defp pump_topic do
    Application.get_env(:pond_pump, :topic)
  end
end
