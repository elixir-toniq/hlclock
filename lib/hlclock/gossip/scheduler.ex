defmodule HLClock.Gossip.Scheduler do
  use GenServer

  alias HLClock.Gossip

  def start_link({args, opts}) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    schedule(args)
    {:ok, args}
  end

  def handle_info(:update_time, args) do
    {:ok, timestamp} = HLClock.now()
    Gossip.broadcast(timestamp)
    schedule(args)
    {:noreply, args}
  end

  defp schedule(args) do
    Process.send_after(self(), :update_time, args.millis)
  end
end
