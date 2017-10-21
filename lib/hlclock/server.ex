defmodule HLClock.Server do
  use GenServer

  alias HLClock.Timestamp

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(opts) do
    Timestamp.new(physical_time(), default_counter(), node_id(opts))
  end

  def handle_call(:send_timestamp, _from, timestamp) do
    case Timestamp.send(timestamp, physical_time()) do
      {:ok, timestamp} ->
        {:reply, {:ok, timestamp}, timestamp}
      {:error, error} ->
        {:reply, {:error, error}, timestamp}
    end
  end

  def handle_call({:recv_timestamp, new_time}, _from, old_time) do
    case Timestamp.recv(old_time, new_time, physical_time()) do
      {:ok, timestamp} ->
        {:reply, {:ok, timestamp}, timestamp}
      {:error, error} ->
        {:reply, {:error, error}, old_time}
    end
  end

  defp physical_time, do: System.os_time(:milliseconds)

  defp default_counter, do: 0

  defp node_id([{:node_id, fun} | _]) when is_function(fun), do: fun.()
end
