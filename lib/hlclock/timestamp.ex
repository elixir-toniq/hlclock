defmodule HLClock.Timestamp do
  @moduledoc """
  HLC Timestamp

  Implements the necessary components of the HLC tuple (i.e. logical time and
  logical counter) with extension to support node ids to provide unique
  timestamps even in cases where time and counter are the same

  Binary representations assume big endianness for interop simplicity with other
  languages/representations.
  """

  defstruct [:time, :counter, :node_id]

  alias __MODULE__, as: T

  @doc """
  Construct a timestamp from its principal components: logical time (initially
  node's physical time), logical counter (initally zero), and the node id
  """
  def new(time, counter, node_id \\ 0) do
    cond do
      byte_size(:binary.encode_unsigned(counter)) > 2 ->
        {:error, :counter_too_large}
      byte_size(:binary.encode_unsigned(node_id)) > 8 ->
        {:error, :node_id_too_large}
      byte_size(:binary.encode_unsigned(time)) > 6 ->
        {:error, :time_too_large}
      true ->
        {:ok, %T{time: time, counter: counter, node_id: node_id}}
    end
  end

  @doc """
  Exhaustive comparison of two timestamps: precedence is in order of time
  component, logical counter, and finally node identifier
  """
  def compare(%{time: t1}, %{time: t2}) when t1 > t2, do: :gt
  def compare(%{time: t1}, %{time: t2}) when t1 < t2, do: :lt
  def compare(%{counter: c1}, %{counter: c2}) when c1 > c2, do: :gt
  def compare(%{counter: c1}, %{counter: c2}) when c1 < c2, do: :lt
  def compare(%{node_id: n1}, %{node_id: n2}) when n1 > n2, do: :gt
  def compare(%{node_id: n1}, %{node_id: n2}) when n1 < n2, do: :lt
  def compare(_ = %{}, _ = %{}), do: :eq

  def less?(t1, t2) do
    compare(t1, t2) == :lt
  end

  @doc """
  Pack the rich Timestamp struct as a 128 bit byte array

  48 bits - Physical time
  16 bits - Logical time
  64 bits - Node ID
  """
  def encode(%{time: t, counter: c, node_id: n}) do
    << t :: size(48) >> <> << c :: size(16) >> <> << n :: size(64) >>
  end

  @doc """
  Construct a Timestamp from the binary representation
  """
  def decode(<<t :: size(48)>> <> <<c::size(16)>> <> <<n::size(64)>>) do
    %T{time: t, counter: c, node_id: n}
  end

  defimpl String.Chars do
    def to_string(%{time: time, counter: counter, node_id: node_id}) do
      "time: #{time}, counter: #{counter}, node_id: #{node_id}"
    end
  end
end
