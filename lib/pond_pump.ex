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
        Logger.debug("Start listing on pin #{pin}")
        Circuits.GPIO.set_interrupts(gpio, :rising)
        loop_power_check(gpio, :inactive)

      {:error, reason} ->
        IO.puts(reason)
    end
  end

  def loop_power_check(gpio, last_state) do
    receive do
      {:circuits_gpio, _pin, _timestamp, 1} ->
        if last_state != :active do
          change_status("active")
        end
        loop_power_check(gpio, :active)
    after
      30_000 ->
        if last_state != :inactive do
          change_status("inactive")
        end
        loop_power_check(gpio, :inactive)
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
