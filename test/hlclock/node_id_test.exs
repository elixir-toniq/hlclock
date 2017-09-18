defmodule HLClock.NodeIdTest do
  use ExUnit.Case, async: true
  import PropertyTest
  import StreamData

  alias HLClock.{NodeId, Generators}

  property "Hashed node ids are within the correct bounds" do
    check all node_name <- unquoted_atom() do
      hash = NodeId.hash(node_name)
      assert 0 <= hash && hash <= Generators.max_node()
    end
  end
end
