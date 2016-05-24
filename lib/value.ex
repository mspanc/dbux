defmodule DBux.Value do
  require Logger

  defstruct type: nil, value: nil, subtype: nil
  @type t :: %DBux.Value{type: :byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd, subtype: :byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd, value: any}


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :byte, value: value}, _) when is_binary(value) do
    if String.length(value) != 1, do: throw {:badarg, :value, :outofrange}

    << hd(to_char_list(value)) >> |> align(:byte)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :byte, value: value}, _) when is_integer(value) do
    if value < 0,    do: throw {:badarg, :value, :outofrange}
    if value > 0xFF, do: throw {:badarg, :value, :outofrange}

    << value >> |> align(:byte)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :boolean, value: value}, endianness) when is_boolean(value) do
    if value do
      marshall(%DBux.Value{type: :uint32, value: 1}, endianness)
    else
      marshall(%DBux.Value{type: :uint32, value: 0}, endianness)
    end
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :int16, value: value}, endianness) when is_integer(value) do
    if value < -0x8000, do: throw {:badarg, :value, :outofrange}
    if value > 0x7FFF,  do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(2)-unit(8)-signed-little >>
      :big_endian ->
        <<value :: size(2)-unit(8)-signed-big >>
    end |> align(:int16)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :uint16, value: value}, endianness) when is_integer(value) do
    if value < 0,      do: throw {:badarg, :value, :outofrange}
    if value > 0xFFFF, do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(2)-unit(8)-unsigned-little >>
      :big_endian ->
        <<value :: size(2)-unit(8)-unsigned-big >>
    end |> align(:uint16)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :int32, value: value}, endianness) when is_integer(value) do
    if value < -0x80000000, do: throw {:badarg, :value, :outofrange}
    if value > 0x7FFFFFFF, do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(4)-unit(8)-signed-little >>
      :big_endian ->
        <<value :: size(4)-unit(8)-signed-big >>
    end |> align(:int32)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :uint32, value: value}, endianness) when is_integer(value) do
    if value < 0,          do: throw {:badarg, :value, :outofrange}
    if value > 0xFFFFFFFF, do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(4)-unit(8)-unsigned-little >>
      :big_endian ->
        <<value :: size(4)-unit(8)-unsigned-big >>
    end |> align(:uint32)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :int64, value: value}, endianness) when is_integer(value) do
    if value < -0x8000000000000000, do: throw {:badarg, :value, :outofrange}
    if value > 0x7FFFFFFFFFFFFFFF,  do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(8)-unit(8)-signed-little >>
      :big_endian ->
        <<value :: size(8)-unit(8)-signed-big >>
    end |> align(:int64)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :uint64, value: value}, endianness) when is_integer(value) do
    if value < 0,                  do: throw {:badarg, :value, :outofrange}
    if value > 0xFFFFFFFFFFFFFFFF, do: throw {:badarg, :value, :outofrange}

    case endianness do
      :little_endian ->
        <<value :: size(8)-unit(8)-unsigned-little >>
      :big_endian ->
        <<value :: size(8)-unit(8)-unsigned-big >>
    end |> align(:uint64)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :double, value: value}, endianness) when is_float(value) do
    case endianness do
      :little_endian ->
        <<value :: float-size(8)-unit(8)-little >>
      :big_endian ->
        <<value :: float-size(8)-unit(8)-big >>
    end |> align(:double)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :unix_fd, value: value}, endianness) when is_integer(value) do
    marshall(%DBux.Value{type: :uint32, value: value}, endianness)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :string, value: value}, endianness) when is_binary(value) do
    if byte_size(value) > 0xFFFFFFFF,        do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>),     do: throw {:badarg, :value, :invalid}
    unless String.valid?(value),             do: throw {:badarg, :value, :invalid}

    case endianness do
      :little_endian ->
        {:ok, length_bitstring, _} = marshall(%DBux.Value{type: :uint32, value: byte_size(value)}, endianness)
        length_bitstring <> << value :: binary-unit(8)-little, 0 >>
      :big_endian ->
        {:ok, length_bitstring, _} = marshall(%DBux.Value{type: :uint32, value: byte_size(value)}, endianness)
        length_bitstring <> << value :: binary-unit(8)-big, 0 >>
    end |> align(:string)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :object_path, value: value}, endianness) when is_binary(value) do
    # TODO add check if it contains a valid object path
    marshall(%DBux.Value{type: :string, value: value}, endianness)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :signature, value: value}, endianness) when is_binary(value) do
    if byte_size(value) > 0xFF,          do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>), do: throw {:badarg, :value, :invalid}
    unless String.valid?(value),         do: throw {:badarg, :value, :invalid}
    # TODO add check if it contains a valid signature

    case endianness do
      :little_endian ->
        {:ok, length_bitstring, _} = marshall(%DBux.Value{type: :byte, value: byte_size(value)}, endianness)
        length_bitstring <> << value :: binary-unit(8)-little, 0 >>
      :big_endian ->
        {:ok, length_bitstring, _} = marshall(%DBux.Value{type: :byte, value: byte_size(value)}, endianness)
        length_bitstring <> << value :: binary-unit(8)-big, 0 >>
    end |> align(:signature)
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :variant, subtype: subtype, value: value}, endianness) do
    signature_bitstring = case subtype do
      :array ->
        throw :todo # TODO

      :struct ->
        throw :todo # TODO

      :variant ->
        throw :todo # TODO

      :dict_entry ->
        throw :todo # TODO

      _ ->
        {:ok, bitstring, _} = %DBux.Value{type: :signature, value: signature(subtype)} |> marshall(endianness)
        bitstring
    end

    {:ok, body_bitstring, body_padding} = %DBux.Value{type: subtype, value: value} |> marshall(endianness)
    {:ok, signature_bitstring <> body_bitstring, body_padding}
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :array, subtype: subtype, value: value}, endianness) when is_list(value) do
    {body_bitstring, last_element_padding} = Enum.reduce(value, {<< >>, 0}, fn(element, acc) ->
      if element.type != subtype, do: throw {:badarg, :value, :invalid}
      {acc_bitstring, _} = acc

      {:ok, element_bitstring, element_padding} = marshall(element, endianness)

      {acc_bitstring <> element_bitstring, element_padding}
    end)

    {:ok, length_bitstring, _} = %DBux.Value{type: :uint32, value: byte_size(body_bitstring) - last_element_padding} |> marshall(endianness)
    {:ok, length_bitstring <> body_bitstring, 0} # FIXME? shouldn't it be aligned by itself?
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :struct, subtype: subtype, value: value}, endianness) when is_list(value) and is_list(subtype) do
    if length(subtype) != length(value), do: throw {:badarg, :value, :signature_and_value_count_mismatch}

    {body_bitstring, last_element_padding, _} = Enum.reduce(value, {<< >>, 0, 0}, fn(element, acc) ->
      {acc_bitstring, _, acc_index} = acc
      if Enum.at(subtype, acc_index) != element.type, do: throw {:badarg, :value, :signature_and_value_type_mismatch}

      {:ok, element_bitstring, element_padding} = marshall(element, endianness)
      {acc_bitstring <> element_bitstring, element_padding, acc_index + 1}
    end)

    {:ok, struct_bitstring, struct_padding} = body_bitstring |> align(:struct)
    {:ok, struct_bitstring, last_element_padding}
  end


  @doc """
  Returns alignment size for given D-Bus type.
  """
  @spec align_size(:byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd) :: number
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


  @doc """
  Returns bitstring that contains 1-byte D-Bus signature of given type.

  Reverse function is `type/1`.
  """
  @spec signature(:byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd) :: Bitstring
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
  # TODO parse compound types


  @doc """
  Returns atom that contains atom identifying type.

  Reverse function is `signature/1`.
  """
  @spec type(Bitstring) :: {:byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry | :unix_fd, nil | list}
  def type(<< "y" >>), do: { :byte, nil }
  def type(<< "b" >>), do: { :boolean, nil }
  def type(<< "n" >>), do: { :int16, nil }
  def type(<< "q" >>), do: { :uint16, nil }
  def type(<< "i" >>), do: { :int32, nil }
  def type(<< "u" >>), do: { :uint32, nil }
  def type(<< "x" >>), do: { :int64, nil }
  def type(<< "t" >>), do: { :uint64, nil }
  def type(<< "d" >>), do: { :double, nil }
  def type(<< "s" >>), do: { :string, nil }
  def type(<< "o" >>), do: { :object_path, nil }
  def type(<< "g" >>), do: { :signature, nil }
  def type(<< "h" >>), do: { :unix_fd, nil }
  # TODO parse compound types


  @doc """
  Aligns given bitstring to bytes appropriate for given type by adding NULL
  bytes at the end.

  It returns `{:ok, aligned_bitstring, added_bytes_count}`.
  """
  @spec marshall(Bitstring, :byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry) :: {:ok, Bitstring, number}
  def align(bitstring, type) when is_binary(bitstring) and is_atom(type) do
    align(bitstring, align_size(type))
  end


  @doc """
  Aligns given bitstring to bytes appropriate for given type by adding `bytes`
  NULL bytes at the end.

  It returns `{:ok, aligned_bitstring, added_bytes_count}`.
  """
  @spec marshall(Bitstring, number) :: {:ok, Bitstring, number}
  def align(bitstring, bytes) when is_binary(bitstring) and is_number(bytes) do
    case rem(byte_size(bitstring), bytes) do
      0 ->
        {:ok, bitstring, 0}

      remaining ->
        missing_bytes = bytes - remaining
        {:ok, bitstring <> String.duplicate(<< 0 >>, missing_bytes), missing_bytes}
    end
  end


  def unmarshall(bitstring, endianness, :array, subtype) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling array: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:array) do
      Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling array: bitstring too short")
      {:error, :bitstring_too_short}

    else
      {subtype_major, subtype_minor} = case subtype do
        {subtype_major, subtype_minor} ->
          {subtype_major, subtype_minor}
        _ ->
          {subtype, nil}
      end

      case unmarshall(bitstring, endianness, :uint32, nil) do
        {:ok, length_value, rest} ->
          length = length_value.value
          Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling array: length = #{inspect(length)}")

          if byte_size(rest) < length do
            Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling array: bitstring too short")
            {:error, :bitstring_too_short}

          else
            {rest, value} = Enum.reduce(1..length, {rest, []}, fn(i, acc) ->
              Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling array elements: i = #{inspect(i)}, acc = #{inspect(acc)}")
              {acc_bitstring, acc_values} = acc

              case unmarshall(acc_bitstring, endianness, subtype_major, subtype_minor) do
                {:ok, value, rest} ->
                  Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalled array elements: i = #{inspect(i)}, value = #{inspect(value)}")
                  {rest, acc_values ++ [value]}

                {:error, reason} ->
                  {:error, reason}
              end
            end)

            {:ok, %DBux.Value{type: :array, subtype: subtype_major, value: value}, rest}
          end

        {:error, error} ->
          {:error, error}
      end
    end
  end


  def unmarshall(bitstring, endianness, :struct, subtype) when is_binary(bitstring) and is_list(subtype) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling struct: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:struct) do
      {:error, :bitstring_too_short}

    else
      {rest, value} = Enum.reduce(subtype, {bitstring, []}, fn(element, acc) ->
        {acc_bitstring, acc_values} = acc

        Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling struct: element = #{inspect(element)}, acc = #{inspect(acc)}")
        case unmarshall(acc_bitstring, endianness, element, nil) do # TODO support nested compound types
          {:ok, value, rest} ->
            {rest, acc_values ++ [value]}

          {:error, reason} ->
            {:error, reason}
        end
      end)

      {:ok, %DBux.Value{type: :struct, subtype: subtype, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :variant, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling variant: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < 1 do
      {:error, :bitstring_too_short}

    else
      case unmarshall(bitstring, endianness, :signature, nil) do
        {:ok, signature_value, rest} ->
          Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling variant: signature = #{inspect(signature_value)}")

          {body_type_major, body_type_minor} = type(signature_value.value)
          case unmarshall(rest, endianness, body_type_major, body_type_minor) do
            {:ok, body_value, rest} ->
              {:ok, %DBux.Value{type: :variant, subtype: body_type_major, value: body_value}, rest}

            {:error, error} ->
              {:error, error}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end


  def unmarshall(bitstring, endianness, :byte, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling byte: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:byte) do
      {:error, :bitstring_too_short}

    else
      << value, rest :: binary >> = bitstring
      {:ok, %DBux.Value{type: :byte, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :uint16, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling uint16: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:uint16) do
      {:error, :bitstring_too_short}

    else
      {value, rest} = case endianness do
        :little_endian ->
          << value_bitstring :: unit(8)-size(2)-unsigned-little, rest :: binary >> = bitstring
          {value_bitstring, rest}

        :big_endian ->
          << value_bitstring :: unit(8)-size(2)-unsigned-big, rest :: binary >> = bitstring
          {value_bitstring, rest}
      end

      {:ok, %DBux.Value{type: :uint16, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :int16, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling int16: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:int16) do
      {:error, :bitstring_too_short}

    else
      {value, rest} = case endianness do
        :little_endian ->
          << value_bitstring :: unit(8)-size(2)-signed-little, rest :: binary >> = bitstring
          {value_bitstring, rest}

        :big_endian ->
          << value_bitstring :: unit(8)-size(2)-signed-big, rest :: binary >> = bitstring
          {value_bitstring, rest}
      end

      {:ok, %DBux.Value{type: :int16, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :uint32, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling uint32: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:uint32) do
      {:error, :bitstring_too_short}

    else
      {value, rest} = case endianness do
        :little_endian ->
          << value_bitstring :: unit(8)-size(4)-unsigned-little, rest :: binary >> = bitstring
          {value_bitstring, rest}

        :big_endian ->
          << value_bitstring :: unit(8)-size(4)-unsigned-big, rest :: binary >> = bitstring
          {value_bitstring, rest}
      end

      {:ok, %DBux.Value{type: :uint32, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :int32, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling int32: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:int32) do
      {:error, :bitstring_too_short}

    else
      {value, rest} = case endianness do
        :little_endian ->
          << value_bitstring :: unit(8)-size(4)-signed-little, rest :: binary >> = bitstring
          {value_bitstring, rest}

        :big_endian ->
          << value_bitstring :: unit(8)-size(4)-signed-big, rest :: binary >> = bitstring
          {value_bitstring, rest}
      end

      {:ok, %DBux.Value{type: :int32, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :uint64, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling uint64: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:uint64) do
      {:error, :bitstring_too_short}

    else
      {value, rest} = case endianness do
        :little_endian ->
          << value_bitstring :: unit(8)-size(8)-unsigned-little, rest :: binary >> = bitstring
          {value_bitstring, rest}

        :big_endian ->
          << value_bitstring :: unit(8)-size(8)-unsigned-big, rest :: binary >> = bitstring
          {value_bitstring, rest}
      end

      {:ok, %DBux.Value{type: :uint64, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :int64, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling int64: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:int64) do
      {:error, :bitstring_too_short}

    else
      {value, rest} = case endianness do
        :little_endian ->
          << value_bitstring :: unit(8)-size(8)-signed-little, rest :: binary >> = bitstring
          {value_bitstring, rest}

        :big_endian ->
          << value_bitstring :: unit(8)-size(8)-signed-big, rest :: binary >> = bitstring
          {value_bitstring, rest}
      end

      {:ok, %DBux.Value{type: :int64, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :signature, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling signature: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:signature) do
      {:error, :bitstring_too_short}

    else
      << length, rest :: binary >> = bitstring
      Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling signature: length = #{inspect(length)}")

      if length != 0 do
        << body :: binary-size(length), 0, rest :: binary >> = rest
        Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling signature: body = #{inspect(body)}")
        {:ok, %DBux.Value{type: :signature, value: body}, rest}

      else
        {:ok, %DBux.Value{type: :signature, value: ""}, rest}
      end
    end
  end


  def unmarshall(bitstring, endianness, :string, nil) when is_binary(bitstring) and is_atom(endianness) do
    Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling string: bitstring = #{inspect(bitstring)}")
    if byte_size(bitstring) < align_size(:string) do
      {:error, :bitstring_too_short}

    else
      case unmarshall(bitstring, endianness, :uint32, nil) do
        {:ok, length_value, rest} ->
          length = length_value.value
          Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling string: length = #{inspect(length)}")

          if length != 0 do
            if byte_size(rest) < length do
              Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling string: bitstring too short")
              {:error, :bitstring_too_short}

            else
              padding_size = rem(length + 1, align_size(:string))
              << body :: binary-size(length), 0, padding :: binary-size(padding_size), rest :: binary >> = rest

              Logger.debug("[DBux.Value #{inspect(self())}] Unmarshalling string: body = #{inspect(body)}")
              {:ok, %DBux.Value{type: :string, value: body}, rest}
            end

          else
            {:ok, %DBux.Value{type: :string, value: ""}, rest}
          end

        {:error, error} ->
          {:error, error}
      end
    end
  end
end
