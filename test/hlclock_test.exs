defmodule HLClockTest do
  use ExUnit.Case
  import PropertyTest
  import HLClock.Generators

  alias HLClock.Timestamp

  describe "new/2" do
    test "uses system time by default" do
      {:ok, clock} = HLClock.new()
      :timer.sleep(100)
      {:ok, new_clock} = HLClock.send_timestamp(clock)

      assert HLClock.before?(clock, new_clock)
      refute HLClock.before?(new_clock, clock)
      assert new_clock.counter == 0
    end
  end

  describe "send_timestamp/2" do
    test "smoke test" do
      {:ok, t0} = HLClock.new(0, 0)
      {:ok, t1} = HLClock.new(1, 0)
      assert Timestamp.less?(t0, t1)
      refute Timestamp.less?(t1, t0)
      assert t0.counter == 0
    end

    property "for a fixed physical time, logical counter incremented" do
      check all time <- ntp_millis() do
        {:ok, t0} = HLClock.new(time, 0)
        {:ok, t1} = HLClock.send_timestamp(t0, 0)
        assert t0.counter == 0
        assert t1.counter == 1
        refute Timestamp.less?(t1, t0)
      end
    end

    test "physical time can move backwards" do
      {:ok, t0} = HLClock.new(10, 0)
      {:ok, t1} = HLClock.send_timestamp(t0, 9)
      assert t0.time == t1.time
      assert t1.counter == 1
    end

    test "send can fail due to excessive drift" do
      {:ok, t0} = HLClock.new(0, 0)
      {:error, err} = HLClock.send_timestamp(t0, HLClock.max_drift() + 1)
      assert err == :clock_drift_violation
    end
  end

  describe "recv_timestamp/2" do
    test "smoke test" do
      {:ok, t0} = HLClock.new(0, 0)
      {:ok, t1} = HLClock.new(0, 1)
      {:ok, t2} = HLClock.recv_timestamp(t0, t1, 0)
      assert t2.time == 0
      assert t2.counter == 1
      assert t2.node_id == 0
    end

    test "events test" do
      events = [
        # valid steps
        {5, :send, nil, timestamp(5, 0, 0)},
        {6, :send, nil, timestamp(6, 0, 0)},
        {10, :recv, timestamp(10, 5, 1), timestamp(10, 6, 0)},

        # Clock jumps backwards
        {7, :send, nil, timestamp(10, 7, 0)},

        # Wall clocks coincide
        {8, :recv, timestamp(10, 4, 1), timestamp(10, 8, 0)},

        # Faulty clock should be discarded
        {9, :recv, timestamp(HLClock.max_drift()+10+1, 888, 1), timestamp(10, 8, 0)},

        # Wall clocks coincide but remote logical clock wins
        {10, :recv, timestamp(10, 99, 1), timestamp(10, 100, 0)},

        # The physical clock has caught up and takes over
        {11, :recv, timestamp(10, 31, 1), timestamp(11, 0, 0)},
        {11, :send, nil, timestamp(11, 1, 0)},
      ]

      events
      |> Enum.reduce(timestamp(0, 0, 0), &check_state/2)
    end
  end

  def timestamp(time, counter, node_id) do
    case Timestamp.new(time, counter, node_id) do
      {:ok, timestamp} ->
        timestamp
      _ ->
        :error
    end
  end

  def check_state({wall_time, event, input, expected}, current) do
    next_clock = progress(event, current, input, wall_time)
    assert next_clock == expected
    next_clock
  end

  def progress(event, current, input, wall_time) do
    case run_event(event, current, input, wall_time) do
      {:ok, next_clock} ->
        next_clock
      {:error, :remote_drift_violation} ->
        current
    end
  end

  def run_event(event, current, input, wall_time) do
    case event do
      :send ->
        HLClock.send_timestamp(current, wall_time)
      :recv ->
        HLClock.recv_timestamp(current, input, wall_time)
    end
  end
end
