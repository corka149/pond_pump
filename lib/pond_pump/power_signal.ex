defmodule PondPump.PowerSignal do
  @moduledoc false

  use GenServer

  require Logger

  # ===== ===== CLIENT ===== =====

  def start_link([light_pin]) do
    GenServer.start_link(__MODULE__, light_pin, name: __MODULE__)
  end

  @spec turn_on_light :: :ok
  def turn_on_light() do
    GenServer.cast(__MODULE__, {:activate})
  end

  @spec turn_off_light :: :ok
  def turn_off_light() do
    GenServer.cast(__MODULE__, {:inactive})
  end

  # ===== ===== SERVER ===== =====

  @impl true
  @spec init(non_neg_integer) :: {:ok, reference}
  def init(light_pin) when is_integer(light_pin) do
    light_gpio = setup_power(light_pin)
    {:ok, light_gpio}
  end

  @impl true
  def handle_cast({:activate}, light_gpio) do
    :ok = Circuits.GPIO.write(light_gpio, 1)
    {:noreply, light_gpio}
  end

  @impl true
  def handle_cast({:inactive}, light_gpio) do
    :ok = Circuits.GPIO.write(light_gpio, 0)
    {:noreply, light_gpio}
  end

  # ===== ===== PRIVATE ===== =====

  defp setup_power(pin) do
    Logger.info("Will turn on light on #{pin}")
    {:ok, gpio} = Circuits.GPIO.open(pin, :output)
    gpio
  end
end
