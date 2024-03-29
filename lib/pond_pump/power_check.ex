defmodule PondPump.PowerCheck do
  use Task, restart: :permanent

  require Logger

  alias PondPump.PowerCheck

  @pump_topic Application.fetch_env!(:pond_pump, :topic)

  @max_timeout 6_000
  @max_on_resends 50

  @enforce_keys [:last_state]
  defstruct last_state: :off, resends: 0

  def start_link([power_pin]) do
    Task.start_link(__MODULE__, :observe, [power_pin])
  end

  @doc """
  Observes a power pin and sends an "active" message via MQTT.
  """
  @spec observe(non_neg_integer) :: no_return
  def observe(power_pin) do
    Logger.info("#{__MODULE__} - Start listing #{power_pin}")

    power_gpio = setup_power(power_pin)

    power_check = new_off_check()

    do_observe(power_gpio, power_check)
  end

  # ===== ===== PRIVATE ===== =====

  defp new_off_check do
    %PowerCheck{last_state: :off}
  end

  defp new_on_check do
    %PowerCheck{last_state: :on, resends: @max_on_resends}
  end

  defp do_observe(power_gpio, power_check) do
    last_state =
      receive do
        notification ->
          transmit(notification, power_check)
      after
        @max_timeout ->
          re_transmit(power_check)
      end

    do_observe(power_gpio, last_state)
  end

  # ===== TRANSMIT =====

  # Got interrupt with value ON = 1
  defp transmit({:circuits_gpio, _pin, _timestamp, 1}, _last_state) do
    Logger.info("#{__MODULE__} - Power active (Notify on #{@pump_topic})")
    publish(<<1>>)

    new_on_check()
  end

  # Got interrupt with value OFF = 0
  defp transmit({:circuits_gpio, _pin, _timestamp, 0}, _last_state) do
    Logger.info("#{__MODULE__} - Power inactive (Notify on #{@pump_topic})")
    publish(<<0>>)

    new_off_check()
  end

  # Unknown
  defp transmit(unknown_notification, last_state) do
    Logger.warn("#{__MODULE__} - Unknown message #{unknown_notification}")
    last_state
  end

  # ===== RE TRANSMIT =====

  # Resent :on state until max resend limit
  defp re_transmit(%PowerCheck{last_state: :on, resends: 0}) do
    Logger.info("#{__MODULE__} - Power still active - reached maximum resend limit")
    publish(<<1>>)

    new_off_check()
  end

  # Resend :on state because limit was not reached
  defp re_transmit(%PowerCheck{last_state: :on, resends: resends} = power_check) do
    Logger.info("#{__MODULE__} - Power still active (remaining resends #{resends - 1})")
    publish(<<1>>)

    %{power_check | resends: resends - 1}
  end

  # Resend :off state
  defp re_transmit(%PowerCheck{last_state: :off, resends: _} = power_check) do
    Logger.info("#{__MODULE__} - Power still inactive")
    publish(<<0>>)

    power_check
  end

  defp publish(val) do
    client_id = Application.get_env(:pond_pump, :client_id)

    case Tortoise311.publish(client_id, @pump_topic, val) do
      :ok -> Logger.debug("#{__MODULE__} - Successful submitted value: #{val}")
      {:error, :unknown_connection} -> Logger.warn("#{__MODULE__} - Unknown conncection")
    end
  end

  # Setup

  defp setup_power(pin) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :input)

    :ok = Circuits.GPIO.set_interrupts(gpio, :both)

    # https://github.com/raspberrypilearning/physical-computing-guide/blob/master/pull_up_down.md
    :ok = Circuits.GPIO.set_pull_mode(gpio, :pulldown)

    gpio
  end
end
