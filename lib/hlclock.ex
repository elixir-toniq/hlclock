defmodule HLClock do
  @moduledoc """
  Documentation for HLClock.
  """

  alias HLClock.Timestamp

  def new(pt \\ default_clock()) do
    Timestamp.new(pt, 0)
  end

  def now(clock, pt \\ default_clock()) do
    if Timestamp.ahead?(clock, pt) do
      Timestamp.increment(clock)
    else
      Timestamp.new(pt, 0)
    end
  end

  def less?(clock1, clock2) do
    Timestamp.compare(clock1, clock2) == :lt
  end

  def update(local, foreign, pt \\ default_clock()) do
    max_pt = max(pt, max(local.time, foreign.time))
    cond do
      max_pt == local.time && max_pt == foreign.time ->
        max_logical = max(local.logical, foreign.logical) + 1
        Timestamp.new(max_pt, max_logical)
      foreign.time > local.time && remote_drifted?(foreign, pt) ->
        local
      max_pt == local.time ->
        Timestamp.new(max_pt, local.logical+1)
      max_pt == foreign.time ->
        Timestamp.new(max_pt, foreign.logical+1)
      true ->
        Timestamp.new(max_pt, 0)
    end
  end

  defp default_clock do
    System.os_time()
  end

  defp remote_drifted?(foreign, pt) do
    foreign.time - pt > max_drift()
  end

  defp max_drift(), do: Application.get_env(:hlclock, :max_drift_millis, 1_000)
end
