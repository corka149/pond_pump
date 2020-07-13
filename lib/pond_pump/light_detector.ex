defmodule PondPump.LightDetecor do
  @moduledoc """
  Detect the address of the pump light
  """

  use Agent, restart: :transient
  require Logger

  def start_link(_opts) do
    {:ok, socket} = :gen_udp.open(12346)
    {:ok, pid} = Agent.start_link(fn -> {socket, nil} end, name: __MODULE__)
    :gen_udp.controlling_process(socket, pid)
    {:ok, pid}
  end

  def set_light_host(host) do
    Agent.update(__MODULE__, fn {socket, _state} -> {socket, host} end)
  end

  def get_light_host() do
    Agent.get(__MODULE__, fn {_socket, state} -> state end)
  end

  receive do
    {:udp, _udp_process, {ia1, ia2, ia3, ia4}, _tmp_udp_port, message} ->
      if message == "Heartbeat" do
        PondPump.LightDetecor.set_light_host("#{ia1}.#{ia2}.#{ia3}.#{ia4}")
      end
    _other ->
      Logger.debug("Received unknown message.")
  end
end
