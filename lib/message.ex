defmodule DBux.Message do
  defstruct type: nil, path: nil, destination: nil, interface: nil, member: nil, values: []
  @type t :: %DBux.Message{type: :method_call | :method_return | :error | :signal, path: String.t, destination: String.t, interface: String.t, member: String.t, values: [] | [any]}


  @spec add_value(%DBux.Message{}, %DBux.Value{}) :: %DBux.Message{}
  def add_value(message, value) when is_map(message) and is_map(value) do
    %{message | values: message[:values] ++ [value]}
  end


  @spec marshall(%DBux.Message{}) :: Bitstring
  def marshall(message) when is_map(message) do

  end
end
