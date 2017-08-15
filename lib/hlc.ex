defmodule Hlc do
  @moduledoc """
  Documentation for Hlc.
  """
  defstruct [:time, :counter, :node_id]

  def new(time, counter, node_id) do
    with :ok <- validate(time, counter, node_id) do
      %__MODULE__{time: time, counter: counter, node_id: node_id}
    end
  end

  def validate(_, counter, _) do
    cond do
      byte_size(:binary.encode_unsigned(counter)) > 2 ->
        {:error, :counter_too_large}
      true ->
        :ok
    end
  end

  def compare(%{time: m1}, %{time: m2}) when m1 > m2, do: :gt
  def compare(%{time: m1}, %{time: m2}) when m1 < m2, do: :lt
  def compare(h1, h2) do
    cond do
      h1.counter > h2.counter -> :gt
      h1.counter < h2.counter -> :lt
      true -> :eq
    end
  end

  def encode(%{time: m, counter: c, node_id: n}), do:
     << m :: size(48) >>
  <> << c :: size(16) >>
  <> << n :: size(64) >>

  def decode(<<m :: size(48)>> <> <<c::size(16)>> <> <<n::size(64)>>), do:
    new(m, c, n)

  defimpl String.Chars do
    def to_string(%{time: time, counter: counter, node_id: node_id}) do
      "time: #{time}, counter: #{counter}, node_id: #{node_id}"
    end
  end
end
