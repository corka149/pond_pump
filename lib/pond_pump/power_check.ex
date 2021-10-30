defmodule PondPump.PowerCheck do
  use Task, restart: :permanent

  def start_link(power_pin, notification_pin) do
    power_gpio = setup_power(power_pin)
    notification_gpio = setup_notification(notification_pin)

    Task.start_link(__MODULE__, :run, [power_gpio, notification_gpio])
  end

  def run(power_gpio, notification_gpio) do
    receive do
      {:circuits_gpio, _pin, _timestamp, value} ->
        :ok = Circuits.GPIO.write(notification_gpio, value)
        run(power_gpio, notification_gpio)
    end
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
