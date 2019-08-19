defmodule HLClock.Server do
  @moduledoc false
  use GenServer

  alias HLClock.{NodeId, Timestamp}

  @gen_server_opts [
    :debug,
    :name,
    :timeout,
    :spawn_opt,
    :hibernate_after
  ]

  def start_link(opts \\ []) do
    {gen_server_opts, other_opts} = Keyword.split(opts, @gen_server_opts)

    hlc_opts = build_opts(other_opts)
    GenServer.start_link(__MODULE__, hlc_opts, gen_server_opts)
  end

  def init(opts) do
    node_id = node_id(opts)
    initial_counter = 0

    data = %{
      node_id: node_id,
      timestamp: Timestamp.new(physical_time(), initial_counter, node_id),
      max_drift: opts[:max_drift]
    }

    Process.send_after(self(), :periodic_send, interval(data))
    {:ok, data}
  end

  def handle_call(:send_timestamp, _from, data) do
    case Timestamp.send(data.timestamp, physical_time(), data.max_drift) do
      {:ok, timestamp} ->
        {:reply, {:ok, timestamp}, %{data | timestamp: timestamp}}

      {:error, error} ->
        {:reply, {:error, error}, data}
    end
  end

  def handle_call(
        {:recv_timestamp, new_time},
        _from,
        %{timestamp: old_time, max_drift: max_drift} = data
      ) do
    case Timestamp.recv(old_time, new_time, physical_time(), max_drift) do
      {:ok, timestamp} ->
        {:reply, {:ok, timestamp}, %{data | timestamp: timestamp}}

      {:error, error} ->
        {:reply, {:error, error}, data}
    end
  end

  def handle_info(:periodic_send, data) do
    Process.send_after(self(), :periodic_send, interval(data))

    case Timestamp.send(data.timestamp, physical_time(), data.max_drift) do
      {:ok, ts} ->
        {:noreply, %{data | timestamp: ts}}

      {:error, _} ->
        {:noreply, data}
    end
  end

  defp physical_time, do: System.os_time(:millisecond)

  defp interval(%{max_drift: max_drift}), do: round(max_drift / 2)

  defp node_id(opts) do
    case opts[:node_id] do
      f when is_function(f) -> f.()
      other -> other
    end
  end

  defp build_opts(opts) do
    base_opts()
    |> Keyword.merge(opts)
  end

  defp base_opts,
    do: [
      name: __MODULE__,
      node_id: NodeId.hash(),
      max_drift: 300_000
    ]
end
