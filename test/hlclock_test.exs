defmodule HLClockTest do
  use ExUnit.Case
  import PropertyTest
  import StreamData

  alias HLClock.Timestamp

  describe "now/2" do
    test "smoke test" do
      clock = HLClock.new()
      s = HLClock.now(clock)
      :timer.sleep(500)
      t = HLClock.new()

      assert HLClock.less?(s, t)
      refute HLClock.less?(t, s)
      assert s.logical == 0
    end

    property "equivalent timestamps increment logical portion" do
      check all time <- constant(1) do
        assert time
        |> HLClock.new
        |> HLClock.now(time)
        |> Map.get(:logical) == 1
      end
    end
  end

  describe "update/2" do
    test "smoke test" do
      events = [
        # valid steps
        {5, :send, nil, Timestamp.new(5, 0)},
        {6, :send, nil, Timestamp.new(6, 0)},
        {10, :recv, Timestamp.new(10, 5), Timestamp.new(10, 6)},

        # Clock jumps backwards
        {7, :send, nil, Timestamp.new(10, 7)},

        # Wall clocks coincide
        {8, :recv, Timestamp.new(10, 4), Timestamp.new(10, 8)},

        # Faulty clock should be discarded
        {9, :recv, Timestamp.new(1100, 888), Timestamp.new(10, 8)},

        # Wall clocks coincide but remote logical clock wins
        {10, :recv, Timestamp.new(10, 99), Timestamp.new(10, 100)},

        # The physical clock has caught up and takes over
        {11, :recv, Timestamp.new(10, 31), Timestamp.new(11, 0)},
        {11, :send, nil, Timestamp.new(11, 1)},
      ]

      events
      |> Enum.reduce(Timestamp.new(0, 0), &check_state/2)
    end
  end

  def check_state({wall_time, event, input, expected}, current) do
    next_clock = case event do
      :send ->
        HLClock.now(current, wall_time)
      :recv ->
        HLClock.update(current, input, wall_time)
    end

    assert next_clock == expected
    next_clock
  end

  property "comparison" do
    check all c1 <- int(0..100),
              c2 <- int(0..100),
              t1 <- int(0..100),
              t2 <- int(0..100),
              h1 <- fixed_map(%{time: constant(t1), logical: constant(c1)}),
              h2 <- fixed_map(%{time: constant(t2), logical: constant(c2)}) do

      result = Timestamp.compare(h1, h2)

      cond do
        t1 > t2 -> assert result == :gt
        t1 < t2 -> assert result == :lt
        c1 > c2 -> assert result == :gt
        c1 < c2 -> assert result == :lt
        true -> assert result == :eq
      end
    end
  end

  property "encoding and decoding" do
    check all logical <- int(0..65_535),
              time    <- int(0..1_000_000),
              node_id <- int(0..1_000_000) do

      hlc = Timestamp.new(time, logical, node_id)

      assert hlc
      |> Timestamp.encode
      |> Timestamp.decode
      |> Timestamp.compare(hlc) == :eq
    end
  end
end
