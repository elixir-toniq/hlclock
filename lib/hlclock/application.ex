defmodule HLClock.Application do
  use Application

  alias HLClock.{Server, Gossip}

  def start(_type, _opts) do
    children = [
      Server,
      Gossip,
    ]

    opts = [strategy: :one_for_one]

    Supervisor.start_link(children, opts)
  end
end
