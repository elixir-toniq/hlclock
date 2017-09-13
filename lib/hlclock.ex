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

  # @doc """
  # clock constructor requires the node_id, a millisecond clock fn and a
  # maximum drift parameter in milliseconds
  # """
  def new(pt \\ physical_time()) do
    GenServer.call(HLClock.Server, :new)
    # Timestamp.new(pt0, 0, node_id)
    # GenServer.start_link(HLClock.Server, opts, [name: HLClock.Server])
  end

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
  Configurable clock synchronization parameter, ε. Defaults to 300 seconds
  """
  def max_drift(), do: Application.get_env(:hlclock, :max_drift_millis, 300_000)

  @doc """
  Current physical time.
  """
  def physical_time(), do: physical_time_fn().()

  @doc """
  Determines if the clock's timestamp "happened before" a different timestamp
  """
  def before?(t1, t2) do
    Timestamp.before?(t1, t2)
  end

  @doc """
  Configurable physical time function. Defaults to System.os_time/1.
  """
  def physical_time_fn() do
    Application.get_env(:hlclock, :physical_time_fn, fn ->
      System.os_time(:milliseconds)
    end)
  end
end
