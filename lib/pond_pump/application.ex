defmodule PondPump.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    if should_start_wizward?() do
      VintageNetWizard.run_wizard()
    end

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
    [
      mqtt_connection(:listener, client_id()),
      pond_pump(:listener),
      pond_pump(:observer)
    ]
  end

  def children(_target) do
    mode = Application.get_env(:pond_pump, :mode)

    [
      mqtt_connection(mode, client_id()),
      pond_pump(mode)
    ]
  end

  def target() do
    Application.get_env(:pond_pump, :target)
  end

  # ===== PRIVATE =====

  defp should_start_wizward? do
    Application.get_env(:pond_pump, :enable_wifi_wizard, false)
  end

  defp pond_pump(:observer) do
    power_check_args = [
      Application.get_env(:pond_pump, :power_in_pin)
    ]

    {PondPump.PowerCheck, power_check_args}
  end

  defp pond_pump(:listener) do
    power_signal_args = [
      Application.get_env(:pond_pump, :light_pin)
    ]

    {PondPump.PowerSignal, power_signal_args}
  end

  defp mqtt_connection(:observer, client_id) do
    host = Application.fetch_env!(:pond_pump, :mqtt_host)
    port = Application.fetch_env!(:pond_pump, :mqtt_port)
    user = Application.fetch_env!(:pond_pump, :mqtt_user)
    password = Application.fetch_env!(:pond_pump, :mqtt_password)

    {
      Tortoise311.Connection,
      [
        client_id: client_id,
        server: {Tortoise311.Transport.Tcp, host: host, port: port},
        handler: {Tortoise311.Handler.Logger, []},
        user_name: user,
        password: password
      ]
    }
  end

  defp mqtt_connection(:listener, client_id) do
    host = Application.fetch_env!(:pond_pump, :mqtt_host)
    port = Application.fetch_env!(:pond_pump, :mqtt_port)
    user = Application.fetch_env!(:pond_pump, :mqtt_user)
    password = Application.fetch_env!(:pond_pump, :mqtt_password)

    {
      Tortoise311.Connection,
      [
        client_id: client_id,
        server: {Tortoise311.Transport.Tcp, host: host, port: port},
        handler: {PondPump.MqttHandler, []},
        user_name: user,
        password: password
      ]
    }
  end

  defp client_id do
    {:ok, hostname} = :inet.gethostname()
    time = System.os_time()
    id = "#{hostname}-#{time}"

    # Make it available to other Processes
    Application.put_env(:pond_pump, :client_id, id)

    id
  end
end
