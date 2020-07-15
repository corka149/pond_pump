defmodule PondPump.PumpLightClient do
  @moduledoc """
  Talks to the pump light.
  """

  require Logger

  def sent_status(device, status) do
    case endpoint() do
      nil -> Logger.info("No host available")
      endpnt ->
        url = endpnt <> "#{device}/#{status}"
        case HTTPoison.get(url) do
          {:ok, _} ->
            "Changed status of #{device} to #{status}"
            |> Logger.debug()

          {:error, _} ->
            ~s/Status of #{device} could not be change to #{status}!
            URL: #{url}/
            |> Logger.error()
        end
    end
  end

  defp endpoint() do
    case PondPump.LightAddressRegister.get_light_host() do
      nil -> nil
      host ->
        "http://#{host}:4000/v1/device/"
    end
  end
end
