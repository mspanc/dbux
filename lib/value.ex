defmodule DBux.Value do
  require Logger

  defstruct type: nil, value: nil, subtype: nil
  @type t :: %DBux.Value{type: DBux.Type.simple_type, subtype: DBux.Type.simple_type, value: any}

  @debug Mix.env != :prod


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
        {:ok, bitstring, _} = %DBux.Value{type: :signature, value: DBux.Type.signature(subtype)} |> marshall(endianness)
        bitstring
    end

    {:ok, body_bitstring, body_padding} = %DBux.Value{type: subtype, value: value} |> marshall(endianness)
    {:ok, signature_bitstring <> body_bitstring, body_padding}
  end


  @spec marshall(%DBux.Value{}, :little_endian | :big_endian) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :array, subtype: subtype, value: value}, endianness) when is_list(value) do
    if length(value) > 67108864, do: throw {:badarg, :value, :outofrange}

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
  def marshall(%DBux.Value{type: :dict_entry} = value, endianness) do
    marshall(value, endianness)
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

    {:ok, struct_bitstring, _} = body_bitstring |> align(:struct)
    {:ok, struct_bitstring, last_element_padding}
  end


  @doc """
  Aligns given bitstring to bytes appropriate for given type by adding NULL
  bytes at the end.

  It returns `{:ok, aligned_bitstring, added_bytes_count}`.
  """
  @spec marshall(Bitstring, :byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :array | :struct | :variant | :dict_entry) :: {:ok, Bitstring, number}
  def align(bitstring, type) when is_binary(bitstring) and is_atom(type) do
    align(bitstring, DBux.Type.align_size(type))
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


  def unmarshall(bitstring, endianness, :array, subtype, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling array: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:array) do
      if @debug, do: debug("Unmarshalling array: bitstring too short", depth)
      {:error, :bitstring_too_short}

    else
      {subtype_major, subtype_minor} = split_subtype(subtype)

      case unmarshall(bitstring, endianness, :uint32, nil, depth + 1) do
        {:ok, body_length_value, rest} ->
          body_length = body_length_value.value
          if byte_size(rest) < body_length do
            if @debug, do: debug("Unmarshalling array: bitstring too short", depth)
            {:error, :bitstring_too_short}

          else
            padding_size = compute_padding_size(body_length, subtype_major)
            << body_bitstring :: binary-size(body_length), padding_bitstring :: binary-size(padding_size), rest :: binary >> = rest
            if @debug, do: debug("Unmarshalling array elements: body_length = #{inspect(body_length)}, padding_size = #{inspect(padding_size)}, body_bitstring = #{inspect(body_bitstring)}, rest = #{inspect(rest)}", depth)

            case parse_array(body_bitstring <> padding_bitstring, endianness, subtype_major, subtype_minor, [], depth) do
              {:ok, value} ->
                if @debug, do: debug("Unmarshalled array elements: value = #{inspect(value)}", depth)
                {:ok, %DBux.Value{type: :array, subtype: subtype_major, value: value}, rest}

              {:error, error} ->
                {:error, error}
            end
          end

        {:error, error} ->
          {:error, error}
      end
    end
  end


  def unmarshall(bitstring, endianness, :dict_entry, subtype, depth) when is_binary(bitstring) and is_list(subtype) and is_atom(endianness) do
    unmarshall(bitstring, endianness, :struct, subtype, depth)
  end


  def unmarshall(bitstring, endianness, :struct, subtype, depth) when is_binary(bitstring) and is_list(subtype) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling struct: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:struct) do
      {:error, :bitstring_too_short}

    else
      {rest, value} = Enum.reduce(subtype, {bitstring, []}, fn(element, acc) ->
        {acc_bitstring, acc_values} = acc

        if @debug, do: debug("Unmarshalling struct: element = #{inspect(element)}, acc = #{inspect(acc)}", depth)
        case unmarshall(acc_bitstring, endianness, element, nil, depth + 1) do # TODO support nested compound types
          {:ok, value, rest} ->
            {rest, acc_values ++ [value]}

          {:error, reason} ->
            {:error, reason}
        end
      end)

      {:ok, %DBux.Value{type: :struct, subtype: subtype, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :variant, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling variant: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < 1 do
      {:error, :bitstring_too_short}

    else
      case unmarshall(bitstring, endianness, :signature, nil, depth + 1) do
        {:ok, signature_value, rest} ->
          if @debug, do: debug("Unmarshalling variant: signature = #{inspect(signature_value)}", depth)

          case DBux.Type.type_from_signature(signature_value.value) do
            {:ok, list_of_types} ->
              {body_type_major, body_type_minor} = case hd(list_of_types) do
                {body_type_major, body_type_minor} ->
                  {body_type_major, body_type_minor}

                body_type ->
                  {body_type, nil}
              end

              case unmarshall(rest, endianness, body_type_major, body_type_minor, depth + 1) do
                {:ok, body_value, rest} ->
                  {:ok, %DBux.Value{type: :variant, subtype: body_type_major, value: body_value}, rest}

                {:error, error} ->
                  {:error, error}
              end

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end


  def unmarshall(bitstring, endianness, :byte, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling byte: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:byte) do
      {:error, :bitstring_too_short}

    else
      << value, rest :: binary >> = bitstring
      {:ok, %DBux.Value{type: :byte, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :uint16, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling uint16: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:uint16) do
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


  def unmarshall(bitstring, endianness, :int16, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling int16: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:int16) do
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


  def unmarshall(bitstring, endianness, :uint32, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling uint32: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:uint32) do
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


  def unmarshall(bitstring, endianness, :unix_fd, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    unmarshall(bitstring, endianness, :uint32, nil, depth)
  end


  def unmarshall(bitstring, endianness, :boolean, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    case unmarshall(bitstring, endianness, :uint32, nil, depth) do
      {:ok, uint32_value, rest} ->
        case uint32_value do
          0 ->
            {:ok, %DBux.Value{type: :boolean, value: false}, rest}
          1 ->
            {:ok, %DBux.Value{type: :boolean, value: true}, rest}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end


  def unmarshall(bitstring, endianness, :int32, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling int32: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:int32) do
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


  def unmarshall(bitstring, endianness, :uint64, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling uint64: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:uint64) do
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


  def unmarshall(bitstring, endianness, :int64, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling int64: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:int64) do
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


  def unmarshall(bitstring, endianness, :double, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling double: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:double) do
      {:error, :bitstring_too_short}

    else
      {value, rest} = case endianness do
        :little_endian ->
          << value_bitstring :: unit(8)-size(8)-float-little, rest :: binary >> = bitstring
          {value_bitstring, rest}

        :big_endian ->
          << value_bitstring :: unit(8)-size(8)-float-big, rest :: binary >> = bitstring
          {value_bitstring, rest}
      end

      {:ok, %DBux.Value{type: :double, value: value}, rest}
    end
  end


  def unmarshall(bitstring, endianness, :signature, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling signature: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:signature) do
      {:error, :bitstring_too_short}

    else
      << length, rest :: binary >> = bitstring
      if @debug, do: debug("Unmarshalling signature: length = #{inspect(length)}", depth)

      if length != 0 do
        << body :: binary-size(length), 0, rest :: binary >> = rest
        if @debug, do: debug("Unmarshalling signature: body = #{inspect(body)}", depth)
        {:ok, %DBux.Value{type: :signature, value: body}, rest}

      else
        {:ok, %DBux.Value{type: :signature, value: ""}, rest}
      end
    end
  end


  def unmarshall(bitstring, endianness, :string, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling string: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:string) do
      {:error, :bitstring_too_short}

    else
      case unmarshall(bitstring, endianness, :uint32, nil, depth + 1) do
        {:ok, length_value, rest} ->
          length = length_value.value
          if length != 0 do
            if byte_size(rest) < length do
              if @debug, do: debug("Unmarshalling string: bitstring too short", depth)
              {:error, :bitstring_too_short}

            else
              padding_size = compute_padding_size(length + 1, :string)
              << body :: binary-size(length), 0, padding :: binary-size(padding_size), rest :: binary >> = rest
              if @debug, do: debug("Unmarshalled string: length = #{inspect(length)}, padding_size = #{inspect(padding_size)}, body = #{inspect(body)}", depth)
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


  def unmarshall(bitstring, endianness, :object_path, nil, depth) when is_binary(bitstring) and is_atom(endianness) do
    unmarshall(bitstring, endianness, :string, nil, depth)
  end


  defp parse_array(bitstring, endianness, subtype_major, subtype_minor, acc, depth) when is_bitstring(bitstring) and is_list(acc) do
    if @debug, do: debug("Unmarshalling array element: next element, bitstring = #{inspect(bitstring)}, subtype_major = #{inspect(subtype_major)}, acc = #{inspect(acc)}", depth)

    case unmarshall(bitstring, endianness, subtype_major, subtype_minor, depth + 1) do
      {:ok, value, rest} ->
        if rest != << >> do
          parsed_bytes = byte_size(bitstring) - byte_size(rest)
          padding_size = compute_padding_size(parsed_bytes, subtype_major)
          << padding :: binary-size(padding_size), rest_without_padding :: binary >> = rest
          if @debug, do: debug("Unmarshalled array element: value = #{inspect(value)}, parsed bytes = #{byte_size(bitstring) - byte_size(rest)}, padding_size = #{inspect(padding_size)}, rest_without_padding = #{inspect(rest_without_padding)}", depth)

          parse_array(rest_without_padding, endianness, subtype_major, subtype_minor, acc ++ [value], depth)

        else
          if @debug, do: debug("Unmarshalled array element: finish", depth)
          {:ok, acc ++ [value]}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end


  defp compute_padding_size(length, type) do
    align = DBux.Type.align_size(type)
    padding = rem(length, align)

    case padding do
      0 ->
        0
      _ ->
        align - padding
    end
  end


  defp split_subtype(subtype) do
    case subtype do
      {subtype_major, subtype_minor} ->
        {subtype_major, subtype_minor}

      _ ->
        {subtype, nil}
    end
  end


  defp debug(message, depth) when is_number(depth) and is_binary(message) do
    Logger.debug("[DBux.Value #{inspect(self())}] #{String.duplicate("  ", depth)}#{message}")
  end
end
