# HLClock

[![Build Status](https://travis-ci.org/toniqsystems/hlclock.svg?branch=master)](https://travis-ci.org/toniqsystems/hlclock) [![Hex pm](http://img.shields.io/hexpm/v/hlclock.svg?style=flat)](https://hex.pm/packages/hlclock)

## About

Hybrid Logical Clocks (HLC) provide a one-way causality detection using a
combination of logical time and physical NTP timestamp. This library adds an
additional mechanism for resolving conflicts between timestamps by adding a
unique node id to each HLC timestamp.

These timestamps can be used in place of standard NTP timestamps in order to
provide consistent snapshots and causality tracking. HLCs have a fixed space
requirement and are bounded close to physical timestamps.

## Installation

First, add `HLClock` to your `mix.exs` dependencies.

```elixir
def deps do
  [{:hlclock, "~> 1.0"}]
end
```

## Usage

Starting in version 1.0.0, the `HLClock.Server` is not started as an application
automatically. `HLClock.start_link/1` is as a short cut to manually start a process:

```elixir
{:ok, clock} = HLClock.start_link()
{:ok, ts} = HLClock.send_timestamp(clock)
```

In practice, it is best to have a single `HLClock` running on any given node.
Toward that end, `HLClock` also provides a `child_spec` that accepts all
standard `GenServer` opts:

```elixir
children = [
  {HLClock, name: :my_hlc_server},
]
```
