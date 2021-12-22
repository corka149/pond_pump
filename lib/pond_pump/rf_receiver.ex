defmodule PondPump.RfReceiver do
  use Task, restart: :permanent

  require Logger

  def start_link([power_pin, receive_pin]) do
    Task.start_link(__MODULE__, :await, [power_pin, receive_pin])
  end

  def await(power_pin, receive_pin) do
    power_gpio = setup_power(power_pin)
    receive_gpio = setup_receive(receive_pin)

    queue = :queue.new()

    queue =
      1..5
      |> Enum.reduce(queue, fn _, acc -> read_to_q(receive_gpio, acc) end)

    do_await(power_gpio, receive_gpio, queue)
  end

  # ===== ===== PRIVATE ===== =====

  defp active_code do
    [1, 1, 1, 1, 1, 0, 0, 0]
  end

  defp do_await(power_gpio, receive_gpio, queue, upkeep \\ 0) do
    upkeep =
      case active_code() == :queue.to_list(queue) do
        true -> 10
        false -> upkeep - 1
      end

    if upkeep > 0 do
      Logger.info("<Light on>")
    end

    queue = :queue.drop(queue)
    queue = read_to_q(receive_gpio, queue)

    do_await(power_gpio, receive_gpio, queue, upkeep)
  end

  # Read from gpio to queue
  defp read_to_q(gpio, queue) do
    Process.sleep(1)

    gpio |> Circuits.GPIO.read() |> :queue.in(queue)
  end

  defp setup_power(pin) do
    Logger.info("Will turn on light on #{pin}")
    {:ok, gpio} = Circuits.GPIO.open(pin, :output)
    gpio
  end

  defp setup_receive(pin) do
    Logger.info("Start listing on #{pin}")
    {:ok, gpio} = Circuits.GPIO.open(pin, :input, initial_value: 0)
    gpio
  end
end
