defmodule HLClock.TimestampTest do
  use ExUnit.Case
  import PropertyTest
  import HLClock.Generators

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

  property "encoded timestamps maintains ordering" do
    check all timestamps <- list_of(timestamp()) do
      assert timestamps
      |> Enum.map(&Timestamp.encode/1)
      |> Enum.sort()
      |> Enum.map(&Timestamp.decode/1) == Enum.sort(timestamps, &Timestamp.less?/2)
    end
  end

  property "encoding and decoding are inversions" do
    check all hlc <- timestamp() do
      assert hlc
      |> Timestamp.encode
      |> Timestamp.decode == hlc
    end
  end
end
