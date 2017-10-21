defmodule HLClock.TimestampTest do
  use ExUnit.Case
  import PropertyTest
  import HLClock.Generators

  doctest HLClock.Timestamp

  alias HLClock.Timestamp

  describe "new/3" do
    property "time must be smaller then the max byte size" do
      check all time <- large_time() do
        assert {:error, :time_too_large} = Timestamp.new(time, 0, 0)
      end
    end

    property "counter must be smaller then the max byte size" do
      check all counter <- large_counter() do
        assert {:error, :counter_too_large} = Timestamp.new(0, counter, 0)
      end
    end

    property "node must be smaller then the max byte size" do
      check all node <- large_node_id() do
        assert {:error, :node_id_too_large} = Timestamp.new(0, 0, node)
      end
    end
  end

  describe "encoding and decoding" do
    property "encoded timestamps maintains ordering" do
      check all timestamps <- list_of(timestamp()) do
        assert timestamps
        |> Enum.map(&Timestamp.encode/1)
        |> Enum.sort()
        |> Enum.map(&Timestamp.decode/1) == Enum.sort(timestamps, &Timestamp.before?/2)
      end
    end

    property "encoding and decoding are inversions" do
      check all hlc <- timestamp() do
        assert hlc
        |> Timestamp.encode
        |> Timestamp.decode == hlc
      end
    end

    property "to_string/1" do
      check all hlc <- timestamp() do
        assert hlc
        |> to_string
        |> String.length == 46
      end
    end

    property "to_string/1 and from_string/1 are symmetric" do
      check all hlc <- timestamp() do
        assert hlc
        |> to_string
        |> Timestamp.from_string == hlc
      end
    end
  end

  describe "send/2" do
    test "smoke test" do
      {:ok, t0} = Timestamp.new(0, 0)
      {:ok, t1} = Timestamp.new(1, 0)
      assert Timestamp.before?(t0, t1)
      refute Timestamp.before?(t1, t0)
      assert t0.counter == 0
    end

    property "for a fixed physical time, logical counter incremented" do
      check all time <- ntp_millis() do
        {:ok, t0} = Timestamp.new(time, 0)
        {:ok, t1} = Timestamp.send(t0, 0)
        assert t0.counter == 0
        assert t1.counter == 1
        refute Timestamp.before?(t1, t0)
      end
    end

    test "physical time can move backwards" do
      {:ok, t0} = Timestamp.new(10, 0, 0)
      {:ok, t1} = Timestamp.send(t0, 9)
      assert t0.time == t1.time
      assert t1.counter == 1
    end

    test "send can fail due to excessive drift" do
      {:ok, t0}     = Timestamp.new(0, 0)
      {:error, err} = Timestamp.send(t0, HLClock.max_drift() + 1)
      assert err == :clock_drift_violation
    end
  end

  describe "recv_timestamp/2" do
    test "smoke test" do
      {:ok, t0} = Timestamp.new(0, 0, 0)
      {:ok, t1} = Timestamp.new(0, 0, 1)
      {:ok, t2} = Timestamp.recv(t0, t1, 0)
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
        Timestamp.send(current, wall_time)
      :recv ->
        Timestamp.recv(current, input, wall_time)
    end
  end
end
