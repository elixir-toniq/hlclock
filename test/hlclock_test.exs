defmodule HLClockTest do
  use ExUnit.Case

  describe "node names" do
    test "HLClocks can be given a node id" do
      {:ok, _hlc} = HLClock.start_link(node_id: 12345)
      {:ok, clock} = HLClock.send_timestamp()
      assert %{node_id: 12345} = clock
    end

    test "if no node id is given then we use a hash of the node name" do
      {:ok, _hlc} = HLClock.start_link()
      {:ok, clock} = HLClock.send_timestamp()
      node_id = HLClock.NodeId.hash()
      assert %{node_id: ^node_id} = clock
    end
  end

  describe "send_timestamp/2" do
    test "uses system time by default" do
      {:ok, _hlc} = HLClock.start_link()
      {:ok, clock} = HLClock.send_timestamp()
      :timer.sleep(100)
      {:ok, new_clock} = HLClock.send_timestamp()

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
      {:ok, _hlc} = HLClock.start_link()
      {:ok, clock} = HLClock.now()
      assert clock.time == HLClock.to_os_time(clock)
    end
  end
end
