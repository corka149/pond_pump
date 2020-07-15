defmodule PondPump.LightAddressRegister do
  @moduledoc """
  Register of pump light address
  """

  use Agent, restart: :permanent

  def start_link(_opts) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def set_light_host(host) do
    Agent.update(__MODULE__, fn _old_host -> host end)
  end

  def get_light_host() do
    Agent.get(__MODULE__, fn host -> host end)
  end
end
