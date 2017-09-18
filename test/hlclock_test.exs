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
end
