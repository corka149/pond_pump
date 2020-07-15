defmodule PondPump.LightDetecor do
  @moduledoc """
  Detect the address of the pump light
  """

  use Task, restart: :permanent
  require Logger

  def start_link(_opts) do
    {:ok, socket} = :gen_udp.open(12346)
    {:ok, pid} = Task.start_link(__MODULE__, :listen, [socket])
    :gen_udp.controlling_process(socket, pid)
    {:ok, pid}
  end

  def listen(socket) do
    Logger.debug("Listing")
    receive do
      {:udp, _udp_process, {ia1, ia2, ia3, ia4}, _tmp_udp_port, 'Beat'} ->
        PondPump.LightAddressRegister.set_light_host("#{ia1}.#{ia2}.#{ia3}.#{ia4}")
      _other ->
        Logger.warn("Received unknown message.")
    end
    listen(socket)
  end
end
