defmodule Hcsr04 do
  @moduledoc """
  A module to interface with the HC-SR04 ultrasonic distance sensor.

  WARN: Linux based systems are not fast enough to keep up with the short frequency
  of modulation based GPIO interfaces like the HC-SR04.

  If you need more accurate measurements, especially over time, you should favour
  an I2C based distance sensor.

  ## Wiring
  The HC-SR04 sensors has 4 pins. VCC and GND are a given.

  ECHO is a input pin receiving the signal modulation when the measurement is completed.
  TRIG is a output pin triggering the measurement process.

  """
  use GenServer

  defmodule State do
    defstruct trig: nil,
              echo: nil,
              read_start: nil,
              readers: []
  end

  @doc """
  Starts the Hcsr04 process linked to the current process.

  ## Options
    * `:trigger` - GPIO pin number for trigger pin
    * `:echo` - GPIO pin number for echo pin

  """
  def start_link(config) when is_list(config) do
    GenServer.start_link(__MODULE__, config)
  end

  @doc """
  Reads the distance in millimeters.

  ## Examples

      iex> Hcsr04.read(pid)
      154.2352463

  """
  def read(pid) do
    GenServer.call(pid, :read)
  end

  # Server (callbacks)

  @impl true
  def init(cfg) do
    {:ok, trigger} = Circuits.GPIO.open(Keyword.fetch!(cfg, :trigger), :output)
    {:ok, echo} = Circuits.GPIO.open(Keyword.fetch!(cfg, :echo), :input)
    :ok = Circuits.GPIO.set_interrupts(echo, :both)

    {:ok, %State{trig: trigger, echo: echo}}
  end

  @impl true
  def handle_call(:read, from, %State{trig: trigger, read_start: nil} = state) do
    Circuits.GPIO.write(trigger, 1)
    :timer.sleep(1)
    Circuits.GPIO.write(trigger, 0)

    {:noreply, %{state | readers: [from | state.readers]}}
  end

  def handle_call(:read, from, %State{read_start: _} = state) do
    {:noreply, %{state | readers: [from | state.readers]}}
  end

  @impl true
  def handle_info({:circuits_gpio, _pin, time, 1}, state) do
    {:noreply, %{state | read_start: time}}
  end

  @impl true
  def handle_info({:circuits_gpio, _pin, _time, 0}, %State{read_start: nil} = state) do
    {:noreply, state}
  end

  def handle_info({:circuits_gpio, _pin, time, 0}, %State{read_start: start} = state) do
    handle_read(time - start, state.readers)

    {:noreply, %{state | read_start: nil, readers: []}}
  end

  defp handle_read(elapsed, readers) do
    distance = time_to_distance(elapsed)

    Enum.each(readers, &GenServer.reply(&1, distance))
  end

  # elapsed in nanoseconds, returns in millimeters
  defp time_to_distance(elapsed), do: elapsed * 0.000343 / 2
end
