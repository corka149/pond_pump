import Config

# Add configuration that is only needed when running on the host here.

config :pond_pump,
  # Observer
  power_in_pin: 19,
  # Listener
  light_pin: 26,
  # General
  topic: "pondpump/149",
  mqtt_host: "localhost",
  mqtt_port: 1883,
  mqtt_user: "jarvis_iot",
  mqtt_password: "S3cr3t_001"

if Mix.env() == :dev do
  # Use Ringlogger as the logger backend and remove :console.
  # See https://hexdocs.pm/ring_logger/readme.html for more information on
  # configuring ring_logger.
  config :logger, backends: [RingLogger]
end
