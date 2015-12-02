defmodule DBux.Value do
  defstruct type: nil, value: nil
  @type t :: %DBux.Value{type: :byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd, value: any}

  @spec marshall(%DBux.Value{}) :: Bitstring
  def marshall(%DBux.Value{type: :byte, value: value}) when is_binary(value) do
    if String.length(value) != 1, do: throw {:badarg, :value, :outofrange}

    << hd(to_char_list(value)) >>
  end


  def marshall(%DBux.Value{type: :byte, value: value}) when is_integer(value) do
    if value < 0,   do: throw {:badarg, :value, :outofrange}
    if value > 255, do: throw {:badarg, :value, :outofrange}

    << value >>
  end
end
