defmodule HLClock.Gossip.PG2Server do
  use GenServer

  def start_link(server_name) do
    GenServer.start_link(__MODULE__, server_name, name: server_name)
  end

  def broadcast(server_name, timestamp) do
    server_name
    |> members
    |> Enum.reject(fn pid -> pid == self() end)
    |> Enum.random
    |> GenServer.cast({:update_time, timestamp})

    :ok
  end

  def members(server_name) do
    server_name
    |> group_name
    |> :pg2.get_members
  end

  def init(server_name) do
    pg2_group = group_name(server_name)
    :ok = :pg2.create(pg2_group)
    :ok = :pg2.join(pg2_group, self())

    {:ok, %{name: pg2_group}}
  end

  def handle_cast({:update_time, timestamp}, state) do
    HLClock.recv_timestamp(timestamp)
    {:noreply, state}
  end

  defp group_name(server_name), do: {:hlclock, server_name}
end
