defmodule HLClockTest do
  use ExUnit.Case, async: false

  setup do
    {:ok, pid} = HLClock.start_link()

    {:ok, hlc: pid}
  end

  describe "send_timestamp/0" do
    test "uses system time by default", %{hlc: hlc} do
      {:ok, clock} = HLClock.send_timestamp(hlc)
      :timer.sleep(100)
      {:ok, new_clock} = HLClock.send_timestamp(hlc)

      assert HLClock.before?(clock, new_clock)
      refute HLClock.before?(new_clock, clock)
      assert new_clock.counter == 0
    end
  end

  describe "recv_timestamp/1" do
    test "works", %{hlc: hlc} do
      {:ok, clock} = HLClock.send_timestamp(hlc)
      # pretend to be from another node
      clock = %{clock | node_id: 12345}
      :timer.sleep(100)
      {:ok, new_clock} = HLClock.recv_timestamp(hlc, clock)

      assert HLClock.before?(clock, new_clock)
      refute HLClock.before?(new_clock, clock)
      assert new_clock.counter == 0
    end
  end

  test "servers can be named" do
    assert {:ok, _} = HLClock.start_link(name: :my_clock)
    assert {:ok, _ts} = HLClock.send_timestamp(:my_clock)
  end

  test "node_id can be assigned as an option" do
    node_id =
      8
      |> :crypto.strong_rand_bytes()
      |> :crypto.bytes_to_integer()

    assert {:ok, hlc} = HLClock.start_link(node_id: node_id)
    assert {:ok, ts} = HLClock.send_timestamp(hlc)
    assert ts.node_id == node_id
  end
end
