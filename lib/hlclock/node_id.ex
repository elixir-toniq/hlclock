defmodule HLClock.NodeId do
  def hash(name \\ Node.self()) do
    name
    |> Atom.to_string
    |> :erlang.phash2
  end
end
