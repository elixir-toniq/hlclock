defmodule HLClock do
  @moduledoc """
  Hybrid Logical Clock

  Provides globally-unique, monotonic timestamps. Timestamps are bounded by the
  clock synchronization constraint, max_drift. By default the max_drift is set
  to 300 seconds.

  In order to account for physical time drift within the system, timestamps
  should regularly be exchanged between nodes. Generate a timestamp at one node
  via HLClock.send_timestamp/1; at the other node, call HLClock.recv_timestamp/2
  with the received timestamp from the first node.

  Inspired by https://www.cse.buffalo.edu/tech-reports/2014-04.pdf
  """
  alias HLClock.Timestamp

  @doc """
  Returns a specification to start an `HLClock.Server` under a supervisor

  In addition to standard `GenServer` opts, this allows for two other
  options to be passed to the underlying server:

  * `:node_id` - a zero arity function returning a 64 bit integer for the node ID
    or a constant value that was precomputed prior to starting; defaults to
    `HLClock.NodeId.hash/0`
  * `:max_drift` - the clock synchronization bound which is applied in either
    direction (i.e. timestamps are too far in the past or too far in the
    future); this value is in milliseconds and defaults to `300_000`
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      type: :worker,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts \\ []) do
    HLClock.Server.start_link(opts)
  end

  @doc """
  Generate a single HLC Timestamp for sending to other nodes or
  local causality tracking
  """
  def send_timestamp(server) do
    GenServer.call(server, :send_timestamp)
  end

  @doc """
  Given the current timestamp for this node and a provided remote timestamp,
  perform the merge of both logical time and logical counters. Returns the new
  current timestamp for the local node.
  """
  def recv_timestamp(server, remote) do
    GenServer.call(server, {:recv_timestamp, remote})
  end

  @doc """
  Functionally equivalent to using `send_timestamp/1`. This generates a timestamp
  for local causality tracking.
  """
  def now(server) do
    GenServer.call(server, :send_timestamp)
  end

  @doc """
  Determines if the clock's timestamp "happened before" a different timestamp
  """
  def before?(t1, t2) do
    Timestamp.before?(t1, t2)
  end
end
