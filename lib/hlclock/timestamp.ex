defmodule HLClock.Timestamp do
  defstruct [:time, :logical, node_id: ""]

  alias __MODULE__, as: T

  def new(time, logical), do: %T{time: time, logical: logical}

  def new(time, logical, node_id) do
    with :ok <- validate(time, logical, node_id) do
      %__MODULE__{time: time, logical: logical, node_id: node_id}
    end
  end

  def validate(_, logical, _) do
    cond do
      byte_size(:binary.encode_unsigned(logical)) > 2 ->
        {:error, :logical_too_large}
      true ->
        :ok
    end
  end

  def increment(%T{logical: l, time: time}) do
    %T{time: time, logical: l+1}
  end

  def ahead?(clock, physical_time) do
    clock.time >= physical_time
  end

  def compare(%{time: m1}, %{time: m2}) when m1 > m2, do: :gt
  def compare(%{time: m1}, %{time: m2}) when m1 < m2, do: :lt
  def compare(clock1, clock2) do
    cond do
      clock1.logical > clock2.logical -> :gt
      clock1.logical < clock2.logical -> :lt
      true -> :eq
    end
  end

  def encode(%{time: m, logical: c, node_id: n}), do:
     << m :: size(48) >>
  <> << c :: size(16) >>
  <> << n :: size(64) >>

  def decode(<<m :: size(48)>> <> <<c::size(16)>> <> <<n::size(64)>>), do:
    new(m, c, n)

  defimpl String.Chars do
    def to_string(%{time: time, logical: logical, node_id: node_id}) do
      "time: #{time}, logical: #{logical}, node_id: #{node_id}"
    end
  end
end
