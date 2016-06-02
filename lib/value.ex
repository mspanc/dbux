defmodule DBux.Value do
  require Logger

  defstruct type: nil, value: nil

  @type t              :: %DBux.Value{type: DBux.Type.simple_type, value: any}
  @type list_of_values :: [] | [%DBux.Value{}]

  @debug !is_nil(System.get_env("DBUX_DEBUG"))


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :byte, value: value}, _) when is_binary(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling byte start: value = #{inspect(value)}", 0)
    if String.length(value) != 1, do: throw {:badarg, :value, :outofrange}

    bitstring <> << hd(to_char_list(value)) >>
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :byte, value: value}, _) when is_integer(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling byte start: value = #{inspect(value)}", 0)
    if value < 0,    do: throw {:badarg, :value, :outofrange}
    if value > 0xFF, do: throw {:badarg, :value, :outofrange}

    bitstring <> << value >>
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :boolean, value: value}, endianness) when is_boolean(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling boolean start: value = #{inspect(value)}", 0)
    if value do
      bitstring |> marshall(%DBux.Value{type: :uint32, value: 1}, endianness)
    else
      bitstring |> marshall(%DBux.Value{type: :uint32, value: 0}, endianness)
    end
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :int16, value: value}, endianness) when is_integer(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling int16 start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    if value < -0x8000, do: throw {:badarg, :value, :outofrange}
    if value > 0x7FFF,  do: throw {:badarg, :value, :outofrange}

    bitstring
    |> align(:int16)
    |> append(
      case endianness do
        :little_endian ->
          <<value :: size(2)-unit(8)-signed-little >>
        :big_endian ->
          <<value :: size(2)-unit(8)-signed-big >>
      end)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :uint16, value: value}, endianness) when is_integer(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling uint16 start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    if value < 0,      do: throw {:badarg, :value, :outofrange}
    if value > 0xFFFF, do: throw {:badarg, :value, :outofrange}

    bitstring
    |> align(:uint16)
    |> append(
      case endianness do
        :little_endian ->
          <<value :: size(2)-unit(8)-unsigned-little >>
        :big_endian ->
          <<value :: size(2)-unit(8)-unsigned-big >>
      end)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :int32, value: value}, endianness) when is_integer(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling int32 start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    if value < -0x80000000, do: throw {:badarg, :value, :outofrange}
    if value > 0x7FFFFFFF, do: throw {:badarg, :value, :outofrange}

    bitstring
    |> align(:int32)
    |> append(
      case endianness do
        :little_endian ->
          <<value :: size(4)-unit(8)-signed-little >>
        :big_endian ->
          <<value :: size(4)-unit(8)-signed-big >>
      end)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :uint32, value: value}, endianness) when is_integer(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling uint32 start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    if value < 0,          do: throw {:badarg, :value, :outofrange}
    if value > 0xFFFFFFFF, do: throw {:badarg, :value, :outofrange}

    bitstring
    |> align(:uint32)
    |> append(
      case endianness do
        :little_endian ->
          <<value :: size(4)-unit(8)-unsigned-little >>
        :big_endian ->
          <<value :: size(4)-unit(8)-unsigned-big >>
      end)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :int64, value: value}, endianness) when is_integer(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling int64 start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    if value < -0x8000000000000000, do: throw {:badarg, :value, :outofrange}
    if value > 0x7FFFFFFFFFFFFFFF,  do: throw {:badarg, :value, :outofrange}

    bitstring
    |> align(:int64)
    |> append(
      case endianness do
        :little_endian ->
          <<value :: size(8)-unit(8)-signed-little >>
        :big_endian ->
          <<value :: size(8)-unit(8)-signed-big >>
      end)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :uint64, value: value}, endianness) when is_integer(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling uint64 start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    if value < 0,                  do: throw {:badarg, :value, :outofrange}
    if value > 0xFFFFFFFFFFFFFFFF, do: throw {:badarg, :value, :outofrange}

    bitstring
    |> align(:uint64)
    |> append(
      case endianness do
        :little_endian ->
          <<value :: size(8)-unit(8)-unsigned-little >>
        :big_endian ->
          <<value :: size(8)-unit(8)-unsigned-big >>
      end)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :double, value: value}, endianness) when is_float(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling double start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    bitstring
    |> align(:double)
    |> append(
      case endianness do
        :little_endian ->
          <<value :: float-size(8)-unit(8)-little >>
        :big_endian ->
          <<value :: float-size(8)-unit(8)-big >>
      end)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :unix_fd, value: value}, endianness) when is_integer(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling unix_fd start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    marshall(bitstring, %DBux.Value{type: :uint32, value: value}, endianness)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :string, value: value}, endianness) when is_binary(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling string start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    if byte_size(value) > 0xFFFFFFFF,        do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>),     do: throw {:badarg, :value, :invalid}
    unless String.valid?(value),             do: throw {:badarg, :value, :invalid}

    bitstring
    |> align(:string)
    |> marshall(%DBux.Value{type: :uint32, value: byte_size(value)}, endianness)
    |> append(
      case endianness do
        :little_endian ->
          << value :: binary-little, 0 >>
        :big_endian ->
          << value :: binary-big, 0 >>
      end)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :object_path, value: value}, endianness) when is_binary(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling object_path start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    # TODO add Bitstring if it contains a valid object path
    marshall(bitstring, %DBux.Value{type: :string, value: value}, endianness)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :signature, value: value}, endianness) when is_binary(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling signature start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)
    if byte_size(value) > 0xFF,          do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>), do: throw {:badarg, :value, :invalid}
    unless String.valid?(value),         do: throw {:badarg, :value, :invalid}
    # TODO add check if it contains a valid signature

    bitstring
    |> align(:signature)
    |> marshall(%DBux.Value{type: :byte, value: byte_size(value)}, endianness)
    |> append(
      case endianness do
        :little_endian ->
          << value :: binary-little, 0 >>
        :big_endian ->
          << value :: binary-big, 0 >>
      end)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :variant, value: value}, endianness) when is_map(value) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling variant start: value = #{inspect(value)}, bitstring = #{inspect(bitstring)}", 0)

    bitstring
    |> align(:signature)
    |> marshall(%DBux.Value{type: :signature, value: DBux.Type.signature(value)}, endianness)
    |> marshall(value, endianness)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: {:array, subtype}, value: elements}, endianness) when is_list(elements) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling array start: elements = #{inspect(elements)}, bitstring = #{inspect(bitstring)}", 0)

    bitstring_plus_placeholder = bitstring <> << 255, 255, 255, 255 >> |> align(subtype)

    bitstring_plus_placeholder_plus_elements = Enum.reduce(elements, bitstring_plus_placeholder, fn(element, acc) ->
      if @debug, do: debug("Marshalling array element: element = #{inspect(element)}, acc = #{inspect(acc)}", 1)
      acc
      |> align(subtype)
      |> marshall(element, endianness)
    end)

    # FIXME nasty hack to substitute length in the existing bitstream
    # we are just assembling it again
    bitstring_length = byte_size(bitstring)
    header_length = byte_size(bitstring_plus_placeholder) - bitstring_length
    << bitstring :: binary-size(bitstring_length), _header :: binary-size(header_length), elements_bitstring :: binary >> = bitstring_plus_placeholder_plus_elements

    bitstring
    |> marshall(%DBux.Value{type: :uint32, value: byte_size(elements_bitstring)}, endianness)
    |> align(subtype)
    |> append(elements_bitstring)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :dict_entry} = value, endianness) when is_binary(bitstring) do
    marshall(bitstring, %{value | type: :struct}, endianness)
  end


  @spec marshall(Bitstring, %DBux.Value{}, DBux.Protocol.endianness) :: Bitstring
  def marshall(bitstring, %DBux.Value{type: :struct, value: elements}, endianness) when is_list(elements) and is_binary(bitstring) do
    if @debug, do: debug("Marshalling struct start: elements = #{inspect(elements)}, bitstring = #{inspect(bitstring)}", 0)

    Enum.reduce(elements, bitstring |> align(:struct), fn(element, acc) ->
      acc
      |> marshall(element, endianness)
    end)
  end



  def unmarshall(bitstring, endianness, {:array, subtype}, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling array: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:array) do
      if @debug, do: debug("Unmarshalling array: bitstring too short", depth)
      {:error, :bitstring_too_short}

    else
      case unmarshall(bitstring, endianness, :uint32, true, depth + 1) do
        {:ok, {body_length, rest}} ->
          if byte_size(rest) < body_length do
            if @debug, do: debug("Unmarshalling array: bitstring too short", depth)
            {:error, :bitstring_too_short}

          else
            << body_bitstring :: binary-size(body_length), rest :: binary >> = rest
            if @debug, do: debug("Unmarshalling array elements: body_length = #{inspect(body_length)}, body_bitstring = #{inspect(body_bitstring)}, rest = #{inspect(rest)}", depth)

            case parse_array(body_bitstring, endianness, hd(subtype), [], unwrap_values, depth) do
              {:ok, elements} ->
                if @debug, do: debug("Unmarshalled array elements: elements = #{inspect(elements)}", depth)
                case unwrap_values do
                  true ->
                    {:ok, {elements, rest}}

                  false ->
                    {:ok, {%DBux.Value{type: :array, value: elements}, rest}}
                end

              {:error, error} ->
                {:error, error}
            end
          end

        {:error, error} ->
          {:error, error}
      end
    end
  end


  def unmarshall(bitstring, endianness, {:dict_entry, subtype}, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    unmarshall(bitstring, endianness, {:struct, subtype}, unwrap_values, depth)
  end


  def unmarshall(bitstring, endianness, {:struct, subtypes}, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling struct: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:struct) do
      {:error, :bitstring_too_short}

    else
      {elements, rest} = Enum.reduce(subtypes, {[], bitstring}, fn(subtype, {elements_acc, bitstring_acc}) ->
        if @debug, do: debug("Unmarshalling struct: subtype = #{inspect(subtype)}, bitstring_acc = #{inspect(bitstring_acc)}, elements_acc = #{inspect(elements_acc)}", depth)
        case unmarshall(bitstring_acc, endianness, subtype, unwrap_values, depth + 1) do
          {:ok, {value, rest}} ->
            {elements_acc ++ [value], rest}

          {:error, reason} ->
            {:error, reason}
        end

        # TODO add paddingment?
      end)

      case unwrap_values do
        true ->
          {:ok, {List.to_tuple(elements), rest}}

        false ->
          {:ok, {%DBux.Value{type: :struct, value: elements}, rest}}
      end
    end
  end


  def unmarshall(bitstring, endianness, :variant, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling variant: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < 1 do
      {:error, :bitstring_too_short}

    else
      case unmarshall(bitstring, endianness, :signature, true, depth + 1) do
        {:ok, {signature, rest}} ->
          if @debug, do: debug("Unmarshalling variant: signature = #{inspect(signature)}", depth)

          case DBux.Type.type_from_signature(signature) do
            {:ok, list_of_types} ->
              {body_type_major, _body_type_minor} = case hd(list_of_types) do
                {body_type_major, body_type_minor} ->
                  {body_type_major, body_type_minor}

                body_type ->
                  {body_type, nil}
              end

              case unmarshall(rest, endianness, body_type_major, unwrap_values, depth + 1) do
                {:ok, {body_value, rest}} ->
                  case unwrap_values do
                    true ->
                      {:ok, {body_value, rest}}

                    false ->
                      {:ok, {%DBux.Value{type: :variant, value: body_value}, rest}}
                  end

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


  def unmarshall(bitstring, endianness, :byte, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling byte: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:byte) do
      {:error, :bitstring_too_short}

    else
      << value, rest :: binary >> = bitstring

      case unwrap_values do
        true ->
          {:ok, {value, rest}}

        false ->
          {:ok, {%DBux.Value{type: :byte, value: value}, rest}}
      end
    end
  end


  def unmarshall(bitstring, endianness, :uint16, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
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

      case unwrap_values do
        true ->
          {:ok, {value, rest}}

        false ->
          {:ok, {%DBux.Value{type: :uint16, value: value}, rest}}
      end
    end
  end


  def unmarshall(bitstring, endianness, :int16, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
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

      case unwrap_values do
        true ->
          {:ok, {value, rest}}

        false ->
          {:ok, {%DBux.Value{type: :int16, value: value}, rest}}
      end
    end
  end


  def unmarshall(bitstring, endianness, :uint32, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
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

      case unwrap_values do
        true ->
          {:ok, {value, rest}}

        false ->
          {:ok, {%DBux.Value{type: :uint32, value: value}, rest}}
      end
    end
  end


  def unmarshall(bitstring, endianness, :unix_fd, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    unmarshall(bitstring, endianness, :uint32, unwrap_values, depth)
  end


  def unmarshall(bitstring, endianness, :boolean, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    case unmarshall(bitstring, endianness, :uint32, unwrap_values, depth) do
      {:ok, uint32_value, rest} ->
        boolean_value = case uint32_value do
          0 ->
            false
          1 ->
            true
        end

        case unwrap_values do
          true ->
            {:ok, boolean_value, rest}

          false ->
            {:ok, {%DBux.Value{type: :boolean, value: boolean_value}, rest}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end


  def unmarshall(bitstring, endianness, :int32, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
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

      case unwrap_values do
        true ->
          {:ok, {value, rest}}

        false ->
          {:ok, {%DBux.Value{type: :int32, value: value}, rest}}
      end
    end
  end


  def unmarshall(bitstring, endianness, :uint64, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
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

      case unwrap_values do
        true ->
          {:ok, {value, rest}}

        false ->
          {:ok, {%DBux.Value{type: :uint64, value: value}, rest}}
      end
    end
  end


  def unmarshall(bitstring, endianness, :int64, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
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

      case unwrap_values do
        true ->
          {:ok, {value, rest}}

        false ->
          {:ok, {%DBux.Value{type: :int64, value: value}, rest}}
      end
    end
  end


  def unmarshall(bitstring, endianness, :double, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
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

      case unwrap_values do
        true ->
          {:ok, {value, rest}}

        false ->
          {:ok, {%DBux.Value{type: :double, value: value}, rest}}
      end
    end
  end


  def unmarshall(bitstring, endianness, :signature, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling signature: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < 2 do # must contain at least size + nul byte
      {:error, :bitstring_too_short}

    else
      << length, rest :: binary >> = bitstring

      if byte_size(rest) <= length do
        {:error, :bitstring_too_short}

      else
        << body :: binary-size(length), 0, rest :: binary >> = rest
        if @debug, do: debug("Unmarshalling signature: length = #{inspect(length)}, body = #{inspect(body)}", depth)

        case unwrap_values do
          true ->
            {:ok, {body, rest}}

          false ->
            {:ok, {%DBux.Value{type: :signature, value: body}, rest}}
        end
      end
    end
  end


  def unmarshall(bitstring, endianness, :string, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    if @debug, do: debug("Unmarshalling string: bitstring = #{inspect(bitstring)}", depth)
    if byte_size(bitstring) < DBux.Type.align_size(:string) do
      {:error, :bitstring_too_short}

    else
      case unmarshall(bitstring, endianness, :uint32, true, depth + 1) do
        {:ok, {length, rest}} ->
          if byte_size(rest) <= length do
            if @debug, do: debug("Unmarshalling string: bitstring too short", depth)
            {:error, :bitstring_too_short}

          else
            << body :: binary-size(length), 0, rest :: binary >> = rest
            if @debug, do: debug("Unmarshalled string: length = #{inspect(length)}, body = #{inspect(body)}", depth)

            case unwrap_values do
              true ->
                {:ok, {body, rest}}

              false ->
                {:ok, {%DBux.Value{type: :string, value: body}, rest}}
            end
          end

        {:error, error} ->
          {:error, error}
      end
    end
  end


  def unmarshall(bitstring, endianness, :object_path, unwrap_values, depth) when is_binary(bitstring) and is_atom(endianness) do
    unmarshall(bitstring, endianness, :string, unwrap_values, depth) |> override_type(:object_path)
  end


  def align(bitstring, type, offset \\ 0)

  @doc """
  Aligns given bitstring to bytes appropriate for given type by adding NULL
  bytes at the end.

  It returns `paddinged_bitstring`.
  """
  @spec align(Bitstring, DBux.Type.t, non_neg_integer) :: Bitstring
  def align(bitstring, type, offset) when is_binary(bitstring) and (is_atom(type) or is_tuple(type)) and is_number(offset) do
    align(bitstring, DBux.Type.align_size(type), offset)
  end


  @doc """
  Aligns given bitstring to bytes appropriate for given type by adding `bytes`
  NULL bytes at the end.

  It returns `paddinged_bitstring`.
  """
  @spec align(Bitstring, non_neg_integer, non_neg_integer) :: Bitstring
  def align(bitstring, boundary, offset) when is_binary(bitstring) and is_number(boundary) and is_number(offset) do
    count = case rem(byte_size(bitstring), boundary) do
      0         -> 0
      remaining -> boundary - remaining
    end + offset

    if @debug, do: debug("Aligning: bitstring = #{inspect(bitstring)}, byte_size(bitstring) = #{inspect(byte_size(bitstring))}, boundary = #{inspect(boundary)}, count = #{inspect(count)}, offset = #{inspect(offset)}", 0)
    bitstring <> String.duplicate(<< 0 >>, count)
  end



  defp parse_array(bitstring, endianness, subtype, acc, unwrap_values, depth) when is_bitstring(bitstring) and is_list(acc) do
    if @debug, do: debug("Unmarshalling array element: next element, bitstring = #{inspect(bitstring)}, subtype = #{inspect(subtype)}, acc = #{inspect(acc)}", depth)

    if bitstring == << >> do
      if @debug, do: debug("Unmarshalled array element: finish (no more bitstring)", depth)
      {:ok, acc}

    else
      case unmarshall(bitstring, endianness, subtype, unwrap_values, depth + 1) do
        {:ok, {value, rest}} ->
          if rest != << >> do
            parsed_bytes = byte_size(bitstring) - byte_size(rest)
            padding_size = DBux.Type.compute_padding_size(parsed_bytes, subtype)
            << _padding :: binary-size(padding_size), rest_without_padding :: binary >> = rest
            if @debug, do: debug("Unmarshalled array element: value = #{inspect(value)}, parsed bytes = #{byte_size(bitstring) - byte_size(rest)}, padding_size = #{inspect(padding_size)}, rest_without_padding = #{inspect(rest_without_padding)}", depth)

            parse_array(rest_without_padding, endianness, subtype, acc ++ [value], unwrap_values, depth)

          else
            if @debug, do: debug("Unmarshalled array element: finish (no more rest)", depth)
            {:ok, acc ++ [value]}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end


  defp override_type({:ok, {value, rest}}, type) when is_map(value), do: {:ok, {%{value | type: type}, rest}}
  defp override_type({:ok, {value, rest}}, _type), do: {:ok, {value, rest}}
  defp override_type({:error, reason}, _type), do: {:error, reason}


  defp append(bitstring1, bitstring2) do
    bitstring1 <> bitstring2
  end


  defp debug(message, depth) when is_number(depth) and is_binary(message) do
    Logger.debug("[DBux.Value #{inspect(self())}] #{String.duplicate("  ", depth)}#{message}")
  end
end
