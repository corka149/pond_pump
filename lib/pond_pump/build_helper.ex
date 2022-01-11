defmodule PondPump.BuildHelper do
  @doc false

  @spec extract_mode! :: :listener | :observer
  def extract_mode! do
    case System.get_env("POND_PUMP_MODE") do
      nil -> raise("No enviroment variable POND_PUMP_MODE")
      "observer" -> :observer
      "listener" -> :listener
      _ -> raise("Invalid value for POND_PUMP_MODE - allowed values: observer or listener")
    end
  end
end
