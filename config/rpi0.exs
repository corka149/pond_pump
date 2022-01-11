import Config

config :pond_pump,
  # Observer
  power_in_pin: 18,
  # Listener
  light_pin: 26,
  # General
  mode: PondPump.BuildHelper.extract_mode!(),
  topic: "pondpump/149",
  mqtt_host: System.fetch_env!("MQTT_HOST"),
  mqtt_port: System.fetch_env!("MQTT_PORT") |> String.to_integer(),
  mqtt_user: System.fetch_env!("MQTT_USER"),
  mqtt_password: System.fetch_env!("MQTT_PASSWORD"),
  enable_wifi_wizard: true

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.
config :logger, backends: [RingLogger]
