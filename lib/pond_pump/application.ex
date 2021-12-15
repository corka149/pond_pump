defmodule PondPump.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PondPump.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: PondPump.Worker.start_link(arg)
        # {PondPump.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    []
  end

  def children(_target) do
    mode = Application.get_env(:pond_pump, :mode)

    [
      pond_pump_task(mode)
    ]
  end

  def target() do
    Application.get_env(:pond_pump, :target)
  end

  # ===== PRIVATE =====

  defp pond_pump_task(:observer) do
    power_check_args = [
      Application.get_env(:pond_pump, :power_in_pin),
      Application.get_env(:pond_pump, :notification_pin)
    ]

    {PondPump.PowerCheck, power_check_args}
  end

  defp pond_pump_task(:listener) do
    power_check_args = [
      Application.get_env(:pond_pump, :power_in_pin),
      Application.get_env(:pond_pump, :receive_pin)
    ]

    {PondPump.RfReceiver, power_check_args}
  end
end
