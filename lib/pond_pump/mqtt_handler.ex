defmodule PondPump.MqttHandler do
  @moduledoc false

  use Tortoise311.Handler

  require Logger

  defstruct []
  alias __MODULE__, as: State

  @topic "pondpump/149"

  def init(_opts) do
    Logger.info("Initializing handler")
    {:ok, %State{}}
  end

  def connection(:up, state) do
    Logger.info("Connection has been established")

    next_actions = [
      {:subscribe, @topic, qos: 0},
      {:subscribe, @topic, qos: 1}
    ]

    {:ok, state, next_actions}
  end

  def connection(:down, state) do
    Logger.info("Connection has been dropped")
    {:ok, state}
  end

  def connection(:terminating, state) do
    Logger.info("Connection is terminating")
    {:ok, state}
  end

  def subscription(:up, topic, state) do
    Logger.info("Subscribed to #{topic}")
    {:ok, state}
  end

  def subscription({:warn, [requested: req, accepted: qos]}, topic, state) do
    Logger.warn("Subscribed to #{topic}; requested #{req} but got accepted with QoS #{qos}")
    {:ok, state}
  end

  def subscription({:error, reason}, topic, state) do
    Logger.error("Error subscribing to #{topic}; #{inspect(reason)}")
    {:ok, state}
  end

  def subscription(:down, topic, state) do
    Logger.info("Unsubscribed from #{topic}")
    {:ok, state}
  end

  def handle_message(topic, publish, state) do
    Logger.info("#{Enum.join(topic, "/")} #{inspect(publish)}")
    IO.puts("#{Enum.join(topic, "/")} #{inspect(publish)}")

    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.warn("Client has been terminated with reason: #{inspect(reason)}")
    :ok
  end
end
