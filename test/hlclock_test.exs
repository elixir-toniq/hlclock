defmodule HLClockTest do
  use ExUnit.Case

  alias HLClock.Timestamp

  describe "send_timestamp/2" do
    test "smoke test" do
      with {:ok, t0} <- HLClock.new(0, 0),
           {:ok, t1} <- HLClock.new(1, 0) do
        assert Timestamp.less?(t0, t1)
        refute Timestamp.less?(t1, t0)
        assert t0.counter == 0
      end
    end

    test "for a fixed physical time, logical counter incremented" do
      with {:ok, t0} <- HLClock.new(0, 0),
           {:ok, t1} <- HLClock.send_timestamp(t0, 0) do
        assert t0.counter == 0
        assert t1.counter == 1
        refute Timestamp.less?(t1, t0)
      end
    end

    test "physical time can move backwards" do
      with {:ok, t0} <- HLClock.new(10, 0),
           {:ok, t1} <- HLClock.send_timestamp(t0, 9) do
        assert t0.time == t1.time
        assert t1.counter == 1
      end
    end

    test "send can fail due to excessive drift" do
      with {:ok, t0} <- HLClock.new(0, 0),
           {:error, err} <- HLClock.send_timestamp(t0, HLClock.max_drift + 1) do
        assert err == :clock_drift_violation
      end
    end
  end

  describe "recv_timestamp/2" do
    test "smoke test" do
      with {:ok, t0} <- HLClock.new(0, 0),
           {:ok, t1} <- HLClock.new(0, 1),
           {:ok, t2} <- HLClock.recv_timestamp(t0, t1, 0) do
        assert t2.time == 0
        assert t2.counter == 1
        assert t2.node_id == 0
      end
    end
  end
end
