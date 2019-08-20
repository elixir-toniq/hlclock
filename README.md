# HLClock

[![Build Status](https://travis-ci.org/toniqsystems/hlclock.svg?branch=master)](https://travis-ci.org/toniqsystems/hlclock)

## About

Hybrid Logical Clocks (HLC) provide a one-way causality detection using a
combination of logical time and physical NTP timestamp. This library adds an
additional mechanism for resolving conflicts between timestamps by adding a
unique node id to each HLC.

These timestamps can be used in place of standard NTP timestamps in order to
provide consistent snapshots and causality tracking. HLCs have a fixed space
requirement and are bounded close to physical timestamps.

## Installation

Now [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hlclock` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:hlclock, "~> 1.0"}]
end
```

## Usage

In order to generate HLCs you'll need an HLClock process:

```elixir
{:ok, clock} = HLClock.start_link()
{:ok, ts} = HLClock.send_timestamp(clock)
```

You can also supervise clock processes:

```elixir
children = [
  {HLClock, name: :my_hlc_server},
]
```

`HLClock.start_link/1` accepts all arguments for `GenServer`.
