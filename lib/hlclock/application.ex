defmodule HLClock.Application do
  use Application

  def start(_type, _opts) do
    children = [
      {HLClock.Server, []},
    ]

    opts = [strategy: :one_for_one]

    Supervisor.start_link(children, opts)
  end
end
