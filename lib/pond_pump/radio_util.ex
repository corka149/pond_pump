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

  @short_delay 1
  @long_delay 2

  @doc """
  Transmit a binary code via GPIO. By default it repeats the code
  four times.

  ## Examples

      iex> {:ok, gpio} = Circuits.GPIO.open(gpio_pin, :output, initial_value: 0)
      iex> once = 1
      iex> RadioUtil.transmit([1, 1, 1, 0, 0], gpio, once)
      iex> # Will be received as 11100
  """
  @spec transmit(list, reference, non_neg_integer) :: :ok
  def transmit(code, gpio, times \\ 4) when is_list(code) do
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

  # ===== ===== DELETE SOON ===== =====

  @doc """
  Await checks incoming raido transmissions for an expected pattern.
  """
  @spec await(list, non_neg_integer) :: :ok
  def await(_code, gpio_pin) do
    {:ok, gpio} = Circuits.GPIO.open(gpio_pin, :input, initial_value: 0)

    do_receive(gpio, 100_000)
  end

  defp do_receive(_gpio, 0) do
    :ok
  end

  defp do_receive(gpio, times) do
    Circuits.GPIO.read(gpio)
    |> IO.write()

    Process.sleep(1)

    do_receive(gpio, times - 1)
  end
end
