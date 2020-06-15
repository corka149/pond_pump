# PondPump

Sends a message when the pond pump gets active.

## Build

Insert SD card and execute the steps:
  * `export MIX_TARGET=rpi0`
  * `export WLAN_SSID=******`
  * `export WLAN_PASSWORD=******`
  * `export PUMP_LIGHT_ADDRESS=http://localhost:4000`
  * `mix firmware`
  * `mix firmware.burn`

## Config

Change the rpi0.exs:
```elixir
config :pond_pump,
  power_in_pin: 18,
  device_name: "pond_pump_149",
  address: System.fetch_env!("PUMP_LIGHT_ADDRESS")
``` 
