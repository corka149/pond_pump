defmodule PondPump.RadioUtil do
  @short_delay 5
  @long_delay 9
  @extended_delay 10

  @doc """
  Transmit a binary code via GPIO. By default it repeats the code
  four times.

  ## Examples

      iex> RadioUtil.transmit([1, 0, 1, 0, 1], 17)

      iex> once = 1
      iex> RadioUtil.transmit([1, 0, 1, 0, 1], 17, once)
  """
  @spec transmit(list, non_neg_integer, non_neg_integer) :: :ok
  def transmit(code, gpio_pin, times \\ 4) when is_list(code) do
    {:ok, gpio} = Circuits.GPIO.open(gpio_pin, :output, initial_value: 0)

    do_rtransmit(gpio, code, times)

    Circuits.GPIO.write(gpio, 0)
  end

  # ===== ===== PRIVATE ===== =====

  defp do_rtransmit(_gpio, _code, 0), do: :ok

  defp do_rtransmit(gpio, code, times) do
    do_transmit(gpio, code)
    do_rtransmit(gpio, code, times - 1)
  end

  defp do_transmit(_, []) do
    Process.sleep(@extended_delay)
    :ok
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
