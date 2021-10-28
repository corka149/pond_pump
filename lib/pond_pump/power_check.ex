defmodule PondPump.PowerCheck do
  use GenServer

  @impl true
  def init(power_pin) do
    {:ok, gpio} = Circuits.GPIO.open(power_pin, :input)

    :ok = Circuits.GPIO.set_interrupts(gpio, :both)

    # https://github.com/raspberrypilearning/physical-computing-guide/blob/master/pull_up_down.md
    :ok = Circuits.GPIO.set_pull_mode(gpio, :pulldown)

    {:ok, gpio}
  end
end
