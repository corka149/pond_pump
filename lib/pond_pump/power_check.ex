defmodule PondPump.PowerCheck do
  use Task, restart: :permanent

  require Logger

  alias PondPump.RadioUtil

  def start_link([power_pin, notification_pin]) do
    Task.start_link(__MODULE__, :observe, [power_pin, notification_pin])
  end

  @doc """
  Observes a power pin and sends an "active" message via a notificaton pin.
  """
  @spec observe(non_neg_integer, non_neg_integer) :: no_return
  def observe(power_pin, notification_pin) do
    Logger.info("Start listing #{power_pin}")
    Logger.info("Ready to write to #{notification_pin}")

    power_gpio = setup_power(power_pin)
    notification_gpio = setup_notification(notification_pin)

    do_observe(power_gpio, notification_gpio)
  end

  # ===== PRIVATE =====

  defp active_code, do: [1, 1, 1, 1, 1, 0, 0, 0]

  defp inactive_code, do: [0, 0, 0, 0, 0, 0, 0, 0]

  defp do_observe(power_gpio, notification_gpio, last_state \\ :off) do
    last_state =
      receive do
        {:circuits_gpio, _pin, _timestamp, 1} ->
          Logger.info("Power active")

          :ok =
            active_code()
            |> RadioUtil.transmit(notification_gpio)

          :on

        {:circuits_gpio, _pin, _timestamp, 0} ->
          Logger.info("Power inactive")

          :ok =
            inactive_code()
            |> RadioUtil.transmit(notification_gpio)

          :off

        unknown_notification ->
          Logger.warn("Unknown message #{unknown_notification}")
          last_state
      after
        5000 ->
          case last_state do
            :on ->
              active_code()
              |> RadioUtil.transmit(notification_gpio)

              :on

            :off ->
              inactive_code()
              |> RadioUtil.transmit(notification_gpio)

              :off
          end
      end

    do_observe(power_gpio, notification_gpio, last_state)
  end

  defp setup_power(pin) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :input)

    :ok = Circuits.GPIO.set_interrupts(gpio, :both)

    # https://github.com/raspberrypilearning/physical-computing-guide/blob/master/pull_up_down.md
    :ok = Circuits.GPIO.set_pull_mode(gpio, :pulldown)

    gpio
  end

  defp setup_notification(pin) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :output)
    gpio
  end
end
