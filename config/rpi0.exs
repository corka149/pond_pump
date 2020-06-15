import Config

config :pond_pump,
  power_in_pin: 18,
  device_name: "pond_pump_149"

config :pump_light,
  address: System.fetch_env!("PUMP_LIGHT_ADDRESS")
