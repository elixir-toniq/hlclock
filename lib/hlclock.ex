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
  clock constructor requires the node_id, a millisecond clock fn and a
  maximum drift parameter in milliseconds
  """
  def new(pt0 \\ default_time(), node_id \\ 0) do
    Timestamp.new(pt0, 0, node_id)
  end

  @doc """
  Generate a single HLC Timestamp for sending to other nodes or
  local causality tracking
  """
  def send_timestamp(%Timestamp{}=old, pt \\ default_time()) do
    nt = max(old.time, pt)
    nc = advance(old, nt)

    with :ok <- handle_drift(old.time, nt) do
      Timestamp.new(nt, nc, old.node_id)
    end
  end

  @doc """
  Given the current timestamp for this node and a provided remote timestamp,
  perform the merge of both logical time and logical counters. Returns the new
  current timestamp for the local node
  """
  def recv_timestamp(local, remote, pt \\ default_time()) do
    max_pt = max(pt, max(remote.time, local.time))

    with {:ok, node_id} <- compare_node_ids(local.node_id, remote.node_id),
         :ok <- handle_drift(remote.time, pt, :remote_drift_violation),
         :ok <- handle_drift(max_pt, pt),
         log <- merge_logical(max_pt, local, remote) do
      Timestamp.new(max_pt, log, node_id)
    end
  end

  @doc """
  Determines if the clock's timestamp "happened before" a different timestamp
  """
  def before?(c1, c2) do
    Timestamp.less?(c1, c2)
  end

  @doc """
  Ensure that System.os_time is returning in milliseconds
  """
  def default_time(), do: System.os_time(:milliseconds)

  @doc """
  Configurable clock synchronization parameter, ε.
  """
  def max_drift(), do: Application.get_env(:hlclock, :max_drift_millis, 300_000)

  defp compare_node_ids(local_id, remote_id) when local_id == remote_id, do:
    {:error, :duplicate_node_id}
  defp compare_node_ids(local_id, _), do: {:ok, local_id}

  defp merge_logical(max_pt, local, remote) do
    cond do
      max_pt == local.time && max_pt == remote.time ->
        max(local.counter, remote.counter) + 1
      max_pt == local.time ->
        local.counter + 1
      max_pt == remote.time ->
        remote.counter + 1
      true ->
        0
    end
  end

  defp handle_drift(l, pt, err \\ :clock_drift_violation) do
    cond do
      drift?(l, pt) ->
        {:error, err}
      true ->
        :ok
    end
  end

  defp drift?(l, pt) do
    abs(l - pt) > max_drift()
  end

  defp advance(old, new_time) do
    cond do
      old.time == new_time ->
        old.counter + 1
      true ->
        0
    end
  end
end
