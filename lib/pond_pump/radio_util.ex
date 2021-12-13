defmodule PondPump.RadioUtil do
  @moduledoc """

  The pattern `11100` will be received through this function

  ## Example

      iex> send = fn _ ->
      ...> Process.sleep 1
      ...> Circuits.GPIO.write(gpio, 1)
      ...> Process.sleep 2
      ...> Circuits.GPIO.write(gpio, 0)
      ...> end
  """

  @short_delay 6
  @long_delay 10
  @extended_delay 11

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

  @doc """
  Await checks incoming raido transmissions for an expected pattern.
  """
  @spec await(list, non_neg_integer) :: :ok
  def await(_code, gpio_pin) do
    {:ok, gpio} = Circuits.GPIO.open(gpio_pin, :input, initial_value: 0)

    do_receive(gpio, 100_000)
  end

  # ===== ===== PRIVATE ===== =====

  def do_receive(_gpio, 0) do
    :ok
  end

  def do_receive(gpio, times) do
    Circuits.GPIO.read(gpio)
    |> IO.write()

    Process.sleep(1)

    do_receive(gpio, times - 1)
  end

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
