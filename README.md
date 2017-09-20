# HLClock

[![Build Status](https://travis-ci.org/keathley/hlclock.svg?branch=master)](https://travis-ci.org/keathley/hlclock)

HLClock provides globally unique, monotonic timestamps. These timestamps
combine both physical time and logical time. This combination means that HLClock
timestamps can track causality and can be used to obtain easily identifiable and
consistent snapshots in distributed systems.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hlc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:hlclock, "~> 0.1.0"}]
end
```

You can then add HLClock to your supervision tree:

```elixir
children = [
  supervisor(HLClock, [])
]
```

Or if you're using Elixir 1.5:

```elixir
children = [
  HLClock,
]
```

## Generating timestamps

To get an idea of how to use HLClock lets look at example. Let's say that we
want to generate a new event and communicate that event to all other nodes.
First we need to generate a local timestamp:

```elixir
def store_event(data) do
  {:ok, timestamp} = HLClock.send_timestamp()
  MyEventProcessor.send_event(data, timestamp)
end
```

On our remote node we can then receive the timestamp:

```elixir
def receive_event(data, timestamp) do
  {:ok, merged} = HLClock.recv_timestamp(timestamp)
  persist(data, merged)
end
```

Now when can determine if an event happened before another event:


```elixir
HLClock.before?(timestamp1, timestamp2)
```

Or we could order all of the events in our system:

```elixir
events
|> Enum.sort(& HLClock.before?(&1.timestamp, &2.timesatmp))
```

## Encoding and Decoding

Timestamps can be encoded into an 128 bit binary:

```elixir
binary = HLClock.Timestamp.encode(t1)
^t1 = HLClock.Timestamp.decode(binary)
```

Encoding is useful if you need to persist timestamps or share them amongst
non-elixir clients. Encoded timestamps retain their ordering so its possible
to simply compare encoded binaries.

## Overriding node names

Node names are included with each timestamp in order to provide additional
tracking information and to provide unique timestamps. By default the node name
is hashed using `:erlang.phash2/2`. This can be overriden by providing a
`:node_id` option to the HLClock supervisor:


```elixir
  children = [
    {HLClock, [node_id: 12345]},
  ]
```

