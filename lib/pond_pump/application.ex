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
    power_check_args = [
      Application.get_env(:pond_pump, :power_in_pin),
      Application.get_env(:pond_pump, :notifcation_pin)
    ]

    [
      {PondPump.PowerCheck, power_check_args}
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: PondPump.Worker.start_link(arg)
      # {PondPump.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:pond_pump, :target)
  end
end
