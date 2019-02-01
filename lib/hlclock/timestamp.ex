defmodule HLClock.Timestamp do
  @moduledoc """
  HLC Timestamp

  Implements the necessary components of the HLC tuple (i.e. logical time and
  logical counter) with extension to support node ids to provide unique
  timestamps even in cases where time and counter are the same

  Binary representations assume big endianness for interop simplicity with other
  languages/representations.
  """

  defstruct [:time, :counter, :node_id]

  alias __MODULE__, as: T

  @type t :: %__MODULE__{
          time: integer(),
          counter: integer(),
          node_id: integer()
        }

  @doc """
  Construct a timestamp from its principal components: logical time (initially
  node's physical time), logical counter (initally zero), and the node id
  """
  def new(time, counter, node_id \\ 0) do
    cond do
      byte_size(:binary.encode_unsigned(counter)) > 2 ->
        {:error, :counter_too_large}

      byte_size(:binary.encode_unsigned(node_id)) > 8 ->
        {:error, :node_id_too_large}

      byte_size(:binary.encode_unsigned(time)) > 6 ->
        {:error, :time_too_large}

      true ->
        {:ok, %T{time: time, counter: counter, node_id: node_id}}
    end
  end

  @doc """
  Generate a single HLC Timestamp for sending to other nodes or
  local causality tracking
  """
  def send(%{time: old_time, counter: counter, node_id: node_id}, pt) do
    new_time = max(old_time, pt)
    new_counter = advance_counter(old_time, counter, new_time)

    with :ok <- handle_drift(old_time, new_time) do
      new(new_time, new_counter, node_id)
    end
  end

  @doc """
  Given the current timestamp for this node and a provided remote timestamp,
  perform the merge of both logical time and logical counters. Returns the new
  current timestamp for the local node
  """
  def recv(local, remote, physical_time) do
    new_time = Enum.max([physical_time, local.time, remote.time])

    with {:ok, node_id} <- compare_node_ids(local.node_id, remote.node_id),
         :ok <-
           handle_drift(remote.time, physical_time, :remote_drift_violation),
         :ok <- handle_drift(new_time, physical_time),
         new_counter <- merge_logical(new_time, local, remote) do
      new(new_time, new_counter, node_id)
    end
  end

  @doc """
  Exhaustive comparison of two timestamps: precedence is in order of time
  component, logical counter, and finally node identifier
  """
  def compare(%{time: t1}, %{time: t2}) when t1 > t2, do: :gt
  def compare(%{time: t1}, %{time: t2}) when t1 < t2, do: :lt
  def compare(%{counter: c1}, %{counter: c2}) when c1 > c2, do: :gt
  def compare(%{counter: c1}, %{counter: c2}) when c1 < c2, do: :lt
  def compare(%{node_id: n1}, %{node_id: n2}) when n1 > n2, do: :gt
  def compare(%{node_id: n1}, %{node_id: n2}) when n1 < n2, do: :lt
  def compare(_ = %{}, _ = %{}), do: :eq

  @doc """
  Determines if the clock's timestamp "happened before" a different timestamp
  """
  def before?(t1, t2) do
    compare(t1, t2) == :lt
  end

  @doc """
  Create a millisecond granularity DateTime struct representing the logical time
  portion of the Timestamp.

  Given that this representation looses the logical counter and node information,
  it should be used as a reference only. Including the counter in the DateTime
  struct would create absurd but still ordered timestamps.

  ## Example

      iex> {:ok, t0} = HLClock.Timestamp.new(1410652800000, 0, 0)
      {:ok, %HLClock.Timestamp{counter: 0, node_id: 0, time: 1410652800000}}

      iex> encoded = HLClock.Timestamp.encode(t0)
      <<1, 72, 113, 117, 132, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

      iex> << time_and_counter :: size(64), _ :: size(64) >> = encoded

      iex> DateTime.from_unix(time_and_counter, :microsecond)
      {:ok, #DateTime<4899-07-30 06:31:40.800000Z>}
  """
  def to_datetime(%T{time: t}) do
    with {:ok, dt} <- DateTime.from_unix(t, :millisecond) do
      dt
    end
  end

  @doc """
  Return the logical, monotonic time portion. Unlike `System.monotonic_time`, if
  timestamps are regularly exchanged with other nodes and/or clients, this
  monotonic timestamp will represent a cluster wide monotonic value.
  """
  def to_os_time(%T{time: t}), do: t

  @doc """
  Pack the rich Timestamp struct as a 128 bit byte array

  48 bits - Physical time
  16 bits - Logical time
  64 bits - Node ID
  """
  def encode(%{time: t, counter: c, node_id: n}) do
    <<t::size(48)>> <> <<c::size(16)>> <> <<n::size(64)>>
  end

  @doc """
  Construct a Timestamp from the binary representation
  """
  def decode(<<t::size(48)>> <> <<c::size(16)>> <> <<n::size(64)>>) do
    %T{time: t, counter: c, node_id: n}
  end

  @doc """
  Recover a Timestamp from the string representation.
  """
  def from_string(tstr) do
    with {:ok, dt, _} <- tstr |> String.slice(0, 24) |> DateTime.from_iso8601(),
         time when is_integer(time) <- DateTime.to_unix(dt, :millisecond),
         {counter, _} <- tstr |> String.slice(25, 4) |> Integer.parse(16),
         {node, _} <- tstr |> String.slice(30, 16) |> Integer.parse(16),
         {:ok, timestamp} <- new(time, counter, node) do
      timestamp
    end
  end

  defp compare_node_ids(local_id, remote_id) when local_id == remote_id,
    do: {:error, :duplicate_node_id}

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
    abs(l - pt) > HLClock.max_drift()
  end

  defp advance_counter(old_time, counter, new_time) do
    cond do
      old_time == new_time ->
        counter + 1

      true ->
        0
    end
  end

  defimpl String.Chars do
    def to_string(ts) do
      logical_time =
        ts
        |> T.to_datetime()
        |> DateTime.to_iso8601()

      counter =
        <<ts.counter::size(16)>>
        |> Base.encode16()

      node_id =
        <<ts.node_id::size(64)>>
        |> Base.encode16()

      "#{logical_time}-#{counter}-#{node_id}"
    end
  end
end
