defmodule HLClock.Timestamp do
  @moduledoc """
  HULC == Hybrid Unique Logical Clock

  Binary representations assume big endianness for interop simplicity with other
  languages/representations.

  """

  defstruct [:time, :counter, :node_id]

  alias __MODULE__, as: T

  def new(time, counter, node_id \\ 0) do
    cond do
      byte_size(:binary.encode_unsigned(counter)) > 2 ->
        {:error, :counter_too_large}
      byte_size(:binary.encode_unsigned(node_id)) > 8 ->
        {:error, :node_id_too_large}
      true ->
        {:ok, %T{time: time, counter: counter, node_id: node_id}}
    end
  end

  @doc "timestamp comparison"
  def compare(%{time: t1}, %{time: t2}) when t1 > t2, do: :gt
  def compare(%{time: t1}, %{time: t2}) when t1 < t2, do: :lt
  def compare(%{counter: c1}, %{counter: c2}) when c1 > c2, do: :gt
  def compare(%{counter: c1}, %{counter: c2}) when c1 < c2, do: :lt
  def compare(%{node_id: n1}, %{node_id: n2}) when n1 > n2, do: :gt
  def compare(%{node_id: n1}, %{node_id: n2}) when n1 < n2, do: :lt
  def compare(_ = %{}, _ = %{}), do: :eq

  @doc "to binary representation"
  def encode(%{time: t, counter: c, node_id: n}) do
    << t :: size(48) >> <> << c :: size(16) >> <> << n :: size(64) >>
  end

  @doc "construct a Timestamp from the binary representation"
  def decode(<<t :: size(48)>> <> <<c::size(16)>> <> <<n::size(64)>>) do
    %T{time: t, counter: c, node_id: n}
  end

  defimpl String.Chars do
    def to_string(%{time: time, counter: counter, node_id: node_id}) do
      "time: #{time}, counter: #{counter}, node_id: #{node_id}"
    end
  end
end
