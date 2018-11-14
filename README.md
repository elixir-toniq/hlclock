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
  [{:hlclock, "~> 0.1.3"}]
end
```

