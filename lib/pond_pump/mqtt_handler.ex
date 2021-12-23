defmodule PondPump.MqttHandler do
  @moduledoc false

  use Tortoise311.Handler

  defstruct []
  alias __MODULE__, as: State

  def init(_opts) do
    IO.puts("Initializing handler")
    {:ok, %State{}}
  end

  def connection(:up, state) do
    IO.puts("Connection has been established")

    next_actions = [
      {:subscribe, "foo/bar", qos: 0}
    ]

    {:ok, state, next_actions}
  end

  def connection(:down, state) do
    IO.puts("Connection has been dropped")
    {:ok, state}
  end

  def connection(:terminating, state) do
    IO.puts("Connection is terminating")
    {:ok, state}
  end

  def subscription(:up, topic, state) do
    IO.puts("Subscribed to #{topic}")
    {:ok, state}
  end

  def subscription({:warn, [requested: req, accepted: qos]}, topic, state) do
    IO.puts("Subscribed to #{topic}; requested #{req} but got accepted with QoS #{qos}")
    {:ok, state}
  end

  def subscription({:error, reason}, topic, state) do
    IO.puts("Error subscribing to #{topic}; #{inspect(reason)}")
    {:ok, state}
  end

  def subscription(:down, topic, state) do
    IO.puts("Unsubscribed from #{topic}")
    {:ok, state}
  end

  def handle_message(topic, publish, state) do
    IO.puts("#{Enum.join(topic, "/")} #{inspect(publish)}")
    {:ok, state}
  end

  def terminate(reason, _state) do
    IO.puts("Client has been terminated with reason: #{inspect(reason)}")
    :ok
  end
end
