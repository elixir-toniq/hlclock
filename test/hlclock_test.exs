defmodule HLClockTest do
  use ExUnit.Case, async: false
  doctest HLClock

  describe "send_timestamp/0" do
    test "uses system time by default" do
      {:ok, clock} = HLClock.send_timestamp()
      :timer.sleep(100)
      {:ok, new_clock} = HLClock.send_timestamp()

      assert HLClock.before?(clock, new_clock)
      refute HLClock.before?(new_clock, clock)
      assert new_clock.counter == 0
    end
  end

  describe "recv_timestamp/1" do
    test "works" do
      {:ok, clock} = HLClock.send_timestamp()
      clock = %{clock | node_id: 12345} # pretend to be from another node
      :timer.sleep(100)
      {:ok, new_clock} = HLClock.recv_timestamp(clock)

      assert HLClock.before?(clock, new_clock)
      refute HLClock.before?(new_clock, clock)
      assert new_clock.counter == 0
    end
  end

  describe "to_datetime/1" do
    test "returns valid DateTime objects" do
      fixed_time = System.os_time(:milliseconds)
      {:ok, clock} = HLClock.Timestamp.new(fixed_time, 0, 0)
      assert :eq == clock
      |> HLClock.to_datetime
      |> DateTime.compare(DateTime.from_unix!(fixed_time, :millisecond))
    end
  end

  describe "to_os_time/1" do
    test "returns time" do
      {:ok, clock} = HLClock.now()
      assert clock.time == HLClock.to_os_time(clock)
    end
  end
end
