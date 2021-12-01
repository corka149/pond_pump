defmodule PondPump.RadioUtil do
  @short_delay 0.00045
  @long_delay 0.00090
  @extended_delay 0.0096

  def transmit(code, gpio_pin) when is_list(code) do
    {:ok, gpio} = Circuits.GPIO.open(gpio_pin, :output)
    do_transmit(gpio, code)

    :ok = Circuits.GPIO.write(gpio, 0)
    Process.sleep(@extended_delay)
  end

  defp do_transmit(gpio, [1 | tail]) do
    :ok = Circuits.GPIO.write(gpio, 1)
    Process.sleep(@short_delay)

    :ok = Circuits.GPIO.write(gpio, 0)
    Process.sleep(@long_delay)

    do_transmit(gpio, tail)
  end

  defp do_transmit(gpio, [0 | tail]) do
    :ok = Circuits.GPIO.write(gpio, 1)
    Process.sleep(@long_delay)

    :ok = Circuits.GPIO.write(gpio, 0)
    Process.sleep(@short_delay)

    do_transmit(gpio, tail)
  end

  defp do_transmit(gpio, [_ | tail]) do
    do_transmit(gpio, tail)
  end
end
