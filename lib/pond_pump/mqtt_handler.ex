defmodule PondPump.MqttHandler do
  @moduledoc false

  use Tortoise311.Handler

  require Logger

  defstruct []
  alias __MODULE__, as: State

  alias PondPump.PowerSignal

  @pump_topic Application.get_env(:pond_pump, :topic) |> String.split("/")

  def init(_opts) do
    Logger.info("#{__MODULE__} - Initializing handler")
    {:ok, %State{}}
  end

  def connection(:up, state) do
    Logger.info("#{__MODULE__} - Connection has been established")

    next_actions = [
      {:subscribe, pump_topic(), qos: 0}
    ]

    {:ok, state, next_actions}
  end

  def connection(:down, state) do
    Logger.info("#{__MODULE__} - Connection has been dropped")
    {:ok, state}
  end

  def connection(:terminating, state) do
    Logger.info("#{__MODULE__} - Connection is terminating")
    {:ok, state}
  end

  def subscription(:up, topic, state) do
    Logger.info("#{__MODULE__} - Subscribed to #{topic}")
    {:ok, state}
  end

  def subscription({:warn, [requested: req, accepted: qos]}, topic, state) do
    Logger.warn(
      "#{__MODULE__} - Subscribed to #{topic}; requested #{req} but got accepted with QoS #{qos}"
    )

    {:ok, state}
  end

  def subscription({:error, reason}, topic, state) do
    Logger.error("#{__MODULE__} - Error subscribing to #{topic}; #{inspect(reason)}")
    {:ok, state}
  end

  def subscription(:down, topic, state) do
    Logger.info("#{__MODULE__} - Unsubscribed from #{topic}")
    {:ok, state}
  end

  def handle_message(topic, <<1>>, state) do
    if topic == @pump_topic do
      Logger.info("#{__MODULE__} - Power active")
      :ok = PowerSignal.turn_on_light()
    else
      Logger.warn("#{__MODULE__} - Unkown topic #{topic}")
    end

    {:ok, state}
  end

  def handle_message(topic, <<0>>, state) do
    if topic == @pump_topic do
      Logger.info("#{__MODULE__} - Power inactive")
      :ok = PowerSignal.turn_off_light()
    else
      Logger.warn("#{__MODULE__} - Unkown topic #{topic}")
    end

    {:ok, state}
  end

  def handle_message(topic, publish, state) do
    Logger.warn("#{__MODULE__} - Unkown message #{Enum.join(topic, "/")} #{inspect(publish)}")

    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.warn("#{__MODULE__} - Client has been terminated with reason: #{inspect(reason)}")
    :ok
  end

  # ===== ===== PRIVATE ===== =====

  defp pump_topic do
    Application.get_env(:pond_pump, :topic)
  end
end
