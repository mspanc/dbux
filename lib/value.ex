defmodule DBux.Value do
  require Logger

  defstruct type: nil, value: nil

  @type t              :: %DBux.Value{type: DBux.Type.simple_type, value: any}
  @type list_of_values :: [] | [%DBux.Value{}]

  @debug !is_nil(System.get_env("DBUX_DEBUG"))


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :byte, value: value}, _) when is_binary(value) do
    if String.length(value) != 1, do: throw {:badarg, :value, :outofrange}

    << hd(to_char_list(value)) >> |> align(:byte)
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :byte, value: value}, _) when is_integer(value) do
    if value < 0,    do: throw {:badarg, :value, :outofrange}
    if value > 0xFF, do: throw {:badarg, :value, :outofrange}

    << value >> |> align(:byte)
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :boolean, value: value}, endianness) when is_boolean(value) do
    if value do
      marshall(%DBux.Value{type: :uint32, value: 1}, endianness)
    else
      marshall(%DBux.Value{type: :uint32, value: 0}, endianness)
    end
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
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


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
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


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
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


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
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


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
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


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
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


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :double, value: value}, endianness) when is_float(value) do
    case endianness do
      :little_endian ->
        <<value :: float-size(8)-unit(8)-little >>
      :big_endian ->
        <<value :: float-size(8)-unit(8)-big >>
    end |> align(:double)
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :unix_fd, value: value}, endianness) when is_integer(value) do
    marshall(%DBux.Value{type: :uint32, value: value}, endianness)
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :string, value: value}, endianness) when is_binary(value) do
    if byte_size(value) > 0xFFFFFFFF,        do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>),     do: throw {:badarg, :value, :invalid}
    unless String.valid?(value),             do: throw {:badarg, :value, :invalid}

    bitstring = case endianness do
      :little_endian ->
        {:ok, {length_bitstring, _}} = marshall(%DBux.Value{type: :uint32, value: byte_size(value)}, endianness)
        length_bitstring <> << value :: binary-unit(8)-little, 0 >>
      :big_endian ->
        {:ok, {length_bitstring, _}} = marshall(%DBux.Value{type: :uint32, value: byte_size(value)}, endianness)
        length_bitstring <> << value :: binary-unit(8)-big, 0 >>
    end

    {:ok, {bitstring, 0}}
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :object_path, value: value}, endianness) when is_binary(value) do
    # TODO add check if it contains a valid object path
    marshall(%DBux.Value{type: :string, value: value}, endianness)
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :signature, value: value}, endianness) when is_binary(value) do
    if byte_size(value) > 0xFF,          do: throw {:badarg, :value, :outofrange}
    if String.contains?(value, << 0 >>), do: throw {:badarg, :value, :invalid}
    unless String.valid?(value),         do: throw {:badarg, :value, :invalid}
    # TODO add check if it contains a valid signature

    case endianness do
      :little_endian ->
        {:ok, {length_bitstring, _}} = marshall(%DBux.Value{type: :byte, value: byte_size(value)}, endianness)
        length_bitstring <> << value :: binary-unit(8)-little, 0 >>
      :big_endian ->
        {:ok, {length_bitstring, _}} = marshall(%DBux.Value{type: :byte, value: byte_size(value)}, endianness)
        length_bitstring <> << value :: binary-unit(8)-big, 0 >>
    end |> align(:signature)
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :variant, value: value}, endianness) when is_map(value) do
    if @debug, do: debug("Marshalling variant start: value = #{inspect(value)}", 0)

    {:ok, {signature_bitstring, _}} = %DBux.Value{type: :signature, value: DBux.Type.signature(value)} |> marshall(endianness)
    if @debug, do: debug("Marshalling variant signature: signature_bitstring = #{inspect(signature_bitstring)}", 0)

    {:ok, {body_bitstring, body_padding}} = value |> marshall(endianness)
    if @debug, do: debug("Marshalling variant body: body_bitstring = #{inspect(body_bitstring)}, body_padding = #{inspect(body_padding)}", 0)
    {:ok, {signature_bitstring <> body_bitstring, body_padding}}
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :array, value: elements}, endianness) when is_list(elements) do
    if @debug, do: debug("Marshalling array start: elements = #{inspect(elements)}", 0)

    case elements do
      [] ->
        %DBux.Value{type: :uint32, value: 0} |> marshall(endianness)

      _ ->
        elements_type = hd(elements).type

        {elements_bitstring, last_element_padding} = Enum.reduce(elements, {<< >>, 0}, fn(element, {bitstring_acc, _}) ->
          if element.type != elements_type, do: throw {:badarg, :value, :array_element_type_mismatch}

          if @debug, do: debug("Marshalling array step: element = #{inspect(element)}, bitstring_acc = #{inspect(bitstring_acc)}", 0)
          {:ok, {element_bitstring, element_padding}} = element |> marshall(endianness)
          if @debug, do: debug("Marshalling array step: element_bitstring = #{inspect(element_bitstring)}, element_padding = #{inspect(element_padding)}", 0)

          {bitstring_acc <> element_bitstring, element_padding}
        end)

        {:ok, {length_bitstring, _}} = %DBux.Value{type: :uint32, value: byte_size(elements_bitstring) - last_element_padding} |> marshall(endianness)
        if @debug, do: debug("Marshalling array done: length_bitstring = #{inspect(length_bitstring)}, body_bitstring = #{inspect(elements_bitstring)}, last_element_padding = #{inspect(last_element_padding)}", 0)
        {:ok, {length_bitstring <> elements_bitstring, last_element_padding}}
    end
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :dict_entry} = value, endianness) do
    marshall(%{value | type: :struct}, endianness)
  end


  @spec marshall(%DBux.Value{}, DBux.Protocol.endianness) :: {:ok, Bitstring, number}
  def marshall(%DBux.Value{type: :struct, value: elements}, endianness) when is_list(elements) do
    if @debug, do: debug("Marshalling struct start: elements = #{inspect(elements)}", 0)

    elements_bitstring = Enum.reduce(elements, << >>, fn(element, bitstring_acc) ->
      if @debug, do: debug("Marshalling struct step pre: element = #{inspect(element)}, bitstring_acc = #{inspect(bitstring_acc)}", 0)
      {:ok, {element_bitstring, element_padding}} = element |> marshall(endianness)
      if @debug, do: debug("Marshalling struct step post: element_bitstring = #{inspect(element_bitstring)}, element_padding = #{inspect(element_padding)}", 0)

      bitstring_acc <> element_bitstring
    end)

    if @debug, do: debug("Marshalling struct done pre: elements_bitstring = #{inspect(elements_bitstring)}, byte_size(elements_bitstring) = #{inspect(byte_size(elements_bitstring))}", 0)
    {:ok, {elements_bitstring, last_element_padding}} = elements_bitstring |> align(:struct)
    if @debug, do: debug("Marshalling struct done post: elements_bitstring = #{inspect(elements_bitstring)}, last_element_padding = #{inspect(last_element_padding)}", 0)
    {:ok, {elements_bitstring, last_element_padding}}
  end


  @doc """
  Aligns given bitstring to bytes appropriate for given type by adding NULL
  bytes at the end.

  It returns `{:ok, aligned_bitstring, added_bytes_count}`.
  """
  @spec align(Bitstring, DBux.Type.t) :: {:ok, Bitstring, number}
  def align(bitstring, type) when is_binary(bitstring) and (is_atom(type) or is_tuple(type)) do
    align(bitstring, DBux.Type.align_size(type))
  end


  @doc """
  Aligns given bitstring to bytes appropriate for given type by adding `bytes`
  NULL bytes at the end.

  It returns `{:ok, aligned_bitstring, added_bytes_count}`.
  """
  @spec align(Bitstring, number) :: {:ok, Bitstring, number}
  def align(bitstring, bytes) when is_binary(bitstring) and is_number(bytes) do
    case rem(byte_size(bitstring), bytes) do
      0 ->
        {:ok, {bitstring, 0}}

      remaining ->
        missing_bytes = bytes - remaining
        {:ok, {bitstring <> String.duplicate(<< 0 >>, missing_bytes), missing_bytes}}
    end
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

        # TODO add alignment?
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


  defp debug(message, depth) when is_number(depth) and is_binary(message) do
    Logger.debug("[DBux.Value #{inspect(self())}] #{String.duplicate("  ", depth)}#{message}")
  end
end
