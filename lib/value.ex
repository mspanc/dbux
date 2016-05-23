defmodule DBux.Value do
  defstruct type: nil, value: nil, subtype: nil
  @type t :: %DBux.Value{type: :byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd, subtype: :byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd, value: any}


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
  def marshall(%DBux.Value{type: :double, value: value}, endianness) when is_float(value) do
    case endianness do
      :little_endian ->
        <<value :: float-size(8)-unit(8)-little >>
      :big_endian ->
        <<value :: float-size(8)-unit(8)-big >>
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :unix_fd, value: value}, endianness) when is_integer(value) do
    marshall(%DBux.Value{type: :uint32, value: value}, endianness)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :string, value: value}, endianness) when is_binary(value) do
    if byte_size(value) > 0xFFFFFFFF,        do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>),     do: throw {:badarg, :value, :invalid}
    unless String.valid?(value),             do: throw {:badarg, :value, :invalid}

    case endianness do
      :little_endian ->
        marshall(%DBux.Value{type: :uint32, value: byte_size(value)}, endianness) <> << value :: binary-unit(8)-little, 0 >> |> align(4)
      :big_endian ->
        marshall(%DBux.Value{type: :uint32, value: byte_size(value)}, endianness) <> << value :: binary-unit(8)-big, 0 >> |> align(4)
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :object_path, value: value}, endianness) when is_binary(value) do
    # TODO add check if it contains a valid object path
    marshall(%DBux.Value{type: :string, value: value}, endianness)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :signature, value: value}, endianness) when is_binary(value) do
    if byte_size(value) > 0xFF,          do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>), do: throw {:badarg, :value, :invalid}
    unless String.valid?(value),         do: throw {:badarg, :value, :invalid}
    # TODO add check if it contains a valid signature

    case endianness do
      :little_endian ->
        marshall(%DBux.Value{type: :byte, value: byte_size(value)}, endianness) <> << value :: binary-unit(8)-little, 0 >>
      :big_endian ->
        marshall(%DBux.Value{type: :byte, value: byte_size(value)}, endianness) <> << value :: binary-unit(8)-big, 0 >>
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :variant, subtype: subtype, value: value}, endianness) do
    signature = case subtype do
      :array ->
        throw :todo # TODO

      :struct ->
        throw :todo # TODO

      :variant ->
        throw :todo # TODO

      :dict_entry ->
        throw :todo # TODO

      _ ->
        %DBux.Value{type: :signature, value: signature(subtype)} |> marshall(endianness)
    end

    body = %DBux.Value{type: subtype, value: value} |> marshall(endianness)

    signature <> body
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :array, subtype: subtype, value: value}, endianness) when is_list(value) do
    body = Enum.reduce(value, << >>, fn(element, acc) ->
      if element.type != subtype, do: throw {:badarg, :value, :invalid}

      acc <> marshall(element, endianness)
    end)

    length = %DBux.Value{type: :uint32, value: byte_size(body)}
      |> marshall(endianness)
#      |> align(align_size(subtype))

    length <> body
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: Bitstring
  def marshall(%DBux.Value{type: :struct, subtype: subtype, value: value}, endianness) when is_list(value) and is_list(subtype) do
    Enum.reduce(value, << >>, fn(element, acc) ->
      # TODO do type and signature check
      acc <> marshall(element, endianness)
    end) |> align(8)
  end


  @spec align_size(atom) :: number
  def align_size(:byte),        do: 1
  def align_size(:boolean),     do: 4
  def align_size(:int16),       do: 2
  def align_size(:uint16),      do: 2
  def align_size(:int32),       do: 4
  def align_size(:uint32),      do: 4
  def align_size(:int64),       do: 8
  def align_size(:uint64),      do: 8
  def align_size(:double),      do: 8
  def align_size(:string),      do: 4
  def align_size(:object_path), do: 4
  def align_size(:signature),   do: 1
  def align_size(:array),       do: 4
  def align_size(:struct),      do: 8
  def align_size(:variant),     do: 1
  def align_size(:dict_entry),  do: 8
  def align_size(:unix_fd),     do: 4


  @spec signature(atom) :: Bitstring
  def signature(:byte),        do: << "y" >>
  def signature(:boolean),     do: << "b" >>
  def signature(:int16),       do: << "n" >>
  def signature(:uint16),      do: << "q" >>
  def signature(:int32),       do: << "i" >>
  def signature(:uint32),      do: << "u" >>
  def signature(:int64),       do: << "x" >>
  def signature(:uint64),      do: << "t" >>
  def signature(:double),      do: << "d" >>
  def signature(:string),      do: << "s" >>
  def signature(:object_path), do: << "o" >>
  def signature(:signature),   do: << "g" >>
  def signature(:unix_fd),     do: << "h" >>


  def align(bitstring, bytes) do
    case rem(byte_size(bitstring), bytes) do
      0 ->
        bitstring

      remaining ->
        missing_bytes = bytes - remaining
        bitstring <> String.duplicate(<< 0 >>, missing_bytes)
    end
  end
end
