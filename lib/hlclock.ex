defmodule HLClock do
  @moduledoc """

  Hybrid Logical Clock

  Provides globally-unique, monotonic timestamps. Timestamps are bounded by the
  clock synchronization constraint, max_drift.

  Implementation assumes that timestamps are (at a minimum) regularly sent; a
  clock at rest will eventually be unable to generate timestamps due to assumed
  bounds on the logical clock relative to physical time.

  In order to account for physical time drift within the system, timestamps
  should regularly be exchanged between nodes. Generate a timestamp at one node
  via HLClock.send_timestamp/1; at the other node, call HLClock.recv_timestamp/2
  with the received timestamp from the first node.

  Inspired by https://www.cse.buffalo.edu/tech-reports/2014-04.pdf
  """

  alias HLClock.Timestamp

  @doc """
  Generate a single HLC Timestamp for sending to other nodes or
  local causality tracking
  """
  def send_timestamp do
    GenServer.call(HLClock.Server, :send_timestamp)
  end

  @doc """
  Given the current timestamp for this node and a provided remote timestamp,
  perform the merge of both logical time and logical counters. Returns the new
  current timestamp for the local node
  """
  def recv_timestamp(remote) do
    GenServer.call(HLClock.Server, {:recv_timestamp, remote})
  end

  @doc """
  Functionally equivalent to using send_timestamp. This generates a timestamp
  for local causality tracking.
  """
  def now do
    GenServer.call(HLClock.Server, :send_timestamp)
  end

  @doc """

  Create a millisecond granularity DateTime struct representing the logical time
  portion of the Timestamp.

  Given that this representation loses the logical counter and node information,
  it should be used as a reference only. Including the counter in the DateTime
  struct would create absurd but still ordered timestamps.

  ## Example

      iex> {:ok, _t0} = HLClock.Timestamp.new(1410652800000, 0, 0)
      {:ok, %HLClock.Timestamp{counter: 0, node_id: 0, time: 1410652800000}}

      ...> encoded = HLClock.Timestamp.encode(t0)
      <<1, 72, 113, 117, 132, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      ...> << time_and_counter :: size(64), _ :: size(64) >> = encoded

      ...> DateTime.from_unix(time_and_counter, :microsecond)
      {:ok, #DateTime<4899-07-30 06:31:40.800000Z>}
  """
  def to_datetime(%Timestamp{time: t}) do
    with {:ok, dt} <- DateTime.from_unix(t, :millisecond) do
      dt
    end
  end

  @doc """
  Return the logical, monotonic time portion. Unlike `System.monotonic_time`, if
  timestamps are regularly exchanged with other nodes and/or clients, this
  monotonic timestamp will represent a cluster wide monotonic value.
  """
  def to_os_time(%Timestamp{time: t}), do: t

  @doc """
  Configurable clock synchronization parameter, ε. Defaults to 300 seconds
  """
  def max_drift(), do: Application.get_env(:hlclock, :max_drift_millis, 300_000)

  @doc """
  Determines if the clock's timestamp "happened before" a different timestamp
  """
  def before?(t1, t2) do
    Timestamp.before?(t1, t2)
  end
end
