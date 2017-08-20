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

  alias __MODULE__, as: Clock
  alias HLClock.Timestamp

  defstruct [:clock_fn, :curr_ts]

  @doc """
  clock constructor requires the node_id, a millisecond clock fn and a
  maximum drift parameter in milliseconds
  """
  def new(node_id \\ 0,
    clock_fn \\ &Clock.default_time/0) do
    with {:ok, t0} <- Timestamp.new(clock_fn.(), 0, node_id) do
      %Clock{clock_fn: clock_fn,
             curr_ts: t0}
    end
  end

  @doc "generate a new timestamp"
  def send_timestamp(%Clock{curr_ts: old, clock_fn: cfn} = clock) do
    pt = cfn.()
    nt = max(old.time, pt)
    nc = advance(old, nt)

    cond do
      drift?(clock, nt, pt) ->
        {:error, :clock_drift_violation}
      true ->
        # counter overflow is handled by Timestamp.new
        with {:ok, new_ts} <- Timestamp.new(nt, nc, old.node_id) do
          {:ok, %Clock{clock | curr_ts: new_ts}}
        end
    end
  end

  defp advance(old, new_time) do
    cond do
      old.time == new_time ->
        old.counter + 1
      true ->
        0
    end
  end

  @doc "receive a remote timestamp and merge with local"
  def recv_timestamp(%Clock{clock_fn: cfn, curr_ts: local} = clock, msg) do
    pt = cfn.()
    max_pt = max(pt, max(msg.time, local.time))
    cond do
      local.node_id == msg.node_id ->
        {:error, :duplicate_node_id}
      drift?(msg.time, pt) ->
        {:error, :remote_drift_violation}
      drift?(max_pt, pt) ->
        {:error, :clock_drift_violation}
      true ->
        new_log = merge_logical(max_pt, local, msg)
        with {:ok, t} <- Timestamp.new(max_pt, new_log, local.node_id) do
          {:ok, %Clock{clock | curr_ts: t}}
        end
    end
  end

  defp drift?(l, pt) do
    abs(l - pt) > max_drift()
  end

  defp merge_logical(max_pt, local, msg) do
    cond do
      max_pt == local.time && max_pt == msg.time ->
        max(local.counter, msg.counter) + 1
      max_pt == local.time ->
        local.counter + 1
      max_pt == msg.time ->
        msg.counter + 1
      true ->
        0
    end
  end

  @doc "os_time in milliseconds"
  def default_time(), do: System.os_time(:milliseconds)

  defp max_drift(), do: Application.get_env(:hlclock, :max_drift_millis, 300_000)
end
