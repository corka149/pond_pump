import Config

defmodule PondPump.BuildHelper do
  def extract_mode! do
    case System.get_env("POND_PUMP_MODE") do
      nil -> raise("No enviroment variable POND_PUMP_MODE")
      "observer" -> :observer
      "listener" -> :listener
      _ -> raise("Invalid value for POND_PUMP_MODE - allowed values: observer or listener")
    end
  end
end

config :pond_pump,
  # Observer
  notification_pin: 17,
  # Listener
  receive_pin: 27,
  # General
  power_in_pin: 18,
  mode: PondPump.BuildHelper.extract_mode!()
