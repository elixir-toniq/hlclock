defmodule HLClock.Application do
  use Application

  def start(_type, _args) do
    children = [
      HLClock.Server
    ]

    Supervisor.start_link(children, [strategy: :one_for_one])
  end
end
