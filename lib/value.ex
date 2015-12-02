defmodule DBux.Value do
  defstruct type: nil, value: nil
  @type t :: %DBux.Value{type: :byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd, value: any}


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :byte, value: value}, _) when is_binary(value) do
    if String.length(value) != 1, do: throw {:badarg, :value, :outofrange}

    << hd(to_char_list(value)) >>
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :byte, value: value}, _) when is_integer(value) do
    if value < 0,    do: throw {:badarg, :value, :outofrange}
    if value > 0xFF, do: throw {:badarg, :value, :outofrange}

    << value >>
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :boolean, value: value}, endianness) when is_boolean(value) do
    if value do
      marshall(%DBux.Value{type: :uint32, value: 1}, endianness)
    else
      marshall(%DBux.Value{type: :uint32, value: 0}, endianness)
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :int16, value: value}, endianness) when is_integer(value) do
    if value < -0x8000, do: throw {:badarg, :value, :outofrange}
    if value > 0x7FFF,  do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(2)-unit(8)-signed-little >>
      :big_endian ->
        <<value :: size(2)-unit(8)-signed-big >>
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :uint16, value: value}, endianness) when is_integer(value) do
    if value < 0,      do: throw {:badarg, :value, :outofrange}
    if value > 0xFFFF, do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(2)-unit(8)-unsigned-little >>
      :big_endian ->
        <<value :: size(2)-unit(8)-unsigned-big >>
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :int32, value: value}, endianness) when is_integer(value) do
    if value < -0x80000000, do: throw {:badarg, :value, :outofrange}
    if value > 0x7FFFFFFF, do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(4)-unit(8)-signed-little >>
      :big_endian ->
        <<value :: size(4)-unit(8)-signed-big >>
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :uint32, value: value}, endianness) when is_integer(value) do
    if value < 0,          do: throw {:badarg, :value, :outofrange}
    if value > 0xFFFFFFFF, do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(4)-unit(8)-unsigned-little >>
      :big_endian ->
        <<value :: size(4)-unit(8)-unsigned-big >>
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :int64, value: value}, endianness) when is_integer(value) do
    if value < -0x8000000000000000, do: throw {:badarg, :value, :outofrange}
    if value > 0x7FFFFFFFFFFFFFFF,  do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(8)-unit(8)-signed-little >>
      :big_endian ->
        <<value :: size(8)-unit(8)-signed-big >>
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :uint64, value: value}, endianness) when is_integer(value) do
    if value < 0,                  do: throw {:badarg, :value, :outofrange}
    if value > 0xFFFFFFFFFFFFFFFF, do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(8)-unit(8)-unsigned-little >>
      :big_endian ->
        <<value :: size(8)-unit(8)-unsigned-big >>
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :string, value: value}, endianness) when is_binary(value) do
    if Kernel.byte_size(value) > 0xFFFFFFFE, do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>),     do: throw {:badarg, :value, :invalid}

    case endianness do
      :little_endian ->
        marshall(%DBux.Value{type: :uint32, value: Kernel.byte_size(value) + 1}, endianness) <> << value :: binary-unit(8)-little >> <> << 0 >>
      :big_endian ->
        marshall(%DBux.Value{type: :uint32, value: Kernel.byte_size(value) + 1}, endianness) <> << value :: binary-unit(8)-big >> <> << 0 >>
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :object_path, value: value}, endianness) when is_binary(value) do
    # TODO add check if it contains a valid object path
    marshall(%DBux.Value{type: :string, value: value}, endianness)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :signature, value: value}, endianness) when is_binary(value) do
    if Kernel.byte_size(value) > 0xFE,   do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>), do: throw {:badarg, :value, :invalid}
    # TODO add check if it contains a valid signature

    case endianness do
      :little_endian ->
        marshall(%DBux.Value{type: :byte, value: Kernel.byte_size(value) + 1}, endianness) <> << value :: binary-unit(8)-little >> <> << 0 >>
      :big_endian ->
        marshall(%DBux.Value{type: :byte, value: Kernel.byte_size(value) + 1}, endianness) <> << value :: binary-unit(8)-big >> <> << 0 >>
    end
  end
end
