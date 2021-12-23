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
  power_in_pin: 18,
  # Listener
  light_pin: 26,
  # General
  mode: PondPump.BuildHelper.extract_mode!()
