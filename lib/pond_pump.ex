defmodule PondPump do
  @moduledoc """
  Checks a PIN for incoming power and - in case it is - sends a request.
  """

  use Task, restart: :transient

  require Logger

  alias PondPump.PumpLightClient, as: Client

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    pin = Application.get_env(:pond_pump, :power_in_pin, 18)
    case Circuits.GPIO.open(pin, :input) do
      {:ok, gpio} ->
        Logger.info("Start listing on #{pin}")
        Circuits.GPIO.set_interrupts(gpio, :rising)
        loop_power_check(gpio)
      {:error, reason} ->
        IO.puts(reason)
    end
  end

  def loop_power_check(gpio) do
    receive do
      {:circuits_gpio, 18, _timestamp, _value} ->
        change_status("active")
        loop_power_check(gpio)
    after
      60_000 ->
        value = Circuits.GPIO.read(gpio)
        Logger.info("Timeout: Read value #{value}")
        change_status("inactive")
        loop_power_check(gpio)
    end
  end

  def change_status(status) do
    case Application.get_env(:pond_pump, :device_name) do
      nil ->
        Logger.error("Device has no name. Could not change status!")
      device ->
        Client.sent_status(device, status)
    end
  end

end
