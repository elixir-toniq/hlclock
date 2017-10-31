defmodule HLClock.Gossip do
  use Supervisor

  alias HLClock.Gossip.{PG2Server, Scheduler}

  @server_name HLClock.PG2Server

  def broadcast(timestamp) do
    PG2Server.broadcast(@server_name, timestamp)
  end

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      {PG2Server, @server_name},
      {Scheduler, {args(), [name: Scheduler]}},
    ]

    opts = [strategy: :one_for_one]

    Supervisor.init(children, opts)
  end

  defp args do
    %{millis: default_gossip_time()}
  end

  defp default_gossip_time do
    Application.get_env(:hlclock, :gossip_every, 10_000)
  end
end
