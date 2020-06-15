defmodule PondPump.PumpLightClient do
  @moduledoc """
  Talks to the pump light.
  """

  require Logger

  @default_address "http://localhost:4000"

  def sent_status(device, status) do
    url = endpoint() <> "/#{device}/#{status}"

    case HTTPoison.get(url) do
      {:ok, _} ->
        "Changed status of #{device} to #{status}"
        |> Logger.debug()

      {:error, _} ->
        ~s/Status of #{device} could not be change to #{status}!
        URL: #{url}
        /
        |> Logger.error()
    end
  end

  defp endpoint() do
    address = Application.get_env(:pond_pump, :address, @default_address)
    address <> "/v1/device"
  end
end
