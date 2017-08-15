defmodule HlcTest do
  use ExUnit.Case
  import PropertyTest
  import StreamData

  property "comparison" do
    check all c1 <- int(0..100),
              c2 <- int(0..100),
              t1 <- int(0..100),
              t2 <- int(0..100),
              h1 <- fixed_map(%{time: constant(t1), counter: constant(c1)}),
              h2 <- fixed_map(%{time: constant(t2), counter: constant(c2)}) do

      result = Hlc.compare(h1, h2)

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
    check all counter <- int(0..65_535),
              time    <- int(0..1_000_000),
              node_id <- int(0..1_000_000) do

      hlc = Hlc.new(time, counter, node_id)

      assert hlc
      |> Hlc.encode
      |> Hlc.decode
      |> Hlc.compare(hlc) == :eq
    end
  end
end
