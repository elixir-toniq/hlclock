defmodule HLClockTest do
  use ExUnit.Case

  describe "send_timestamp/2" do
    test "uses system time by default" do
      {:ok, clock} = HLClock.send_timestamp()
      :timer.sleep(100)
      {:ok, new_clock} = HLClock.send_timestamp()

      assert HLClock.before?(clock, new_clock)
      refute HLClock.before?(new_clock, clock)
      assert new_clock.counter == 0
    end
  end
end
