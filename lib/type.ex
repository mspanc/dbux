defmodule DBux.Type do
  @type simple_type_name    :: :byte | :boolean | :int16 | :uint16 | :int32 | :uint32 | :int64 | :uint64 | :double | :string | :object_path | :signature | :unix_fd
  @type container_type_name :: :array | :struct | :variant | :dict_entry

  @type simple_type         :: simple_type_name
  @type container_type      :: {container_type_name, [simple_type | container_type]}
  @type t                   :: simple_type | container_type
  @type list_of_types       :: [] | [t]


  @doc """
  Returns bitstring that contains 1-byte D-Bus signature of given type.

  Reverse function is `type/1`.
  """
  @spec signature(simple_type | :variant) :: String.t
  def signature(:byte),        do: "y"
  def signature(:boolean),     do: "b"
  def signature(:int16),       do: "n"
  def signature(:uint16),      do: "q"
  def signature(:int32),       do: "i"
  def signature(:uint32),      do: "u"
  def signature(:int64),       do: "x"
  def signature(:uint64),      do: "t"
  def signature(:double),      do: "d"
  def signature(:string),      do: "s"
  def signature(:object_path), do: "o"
  def signature(:signature),   do: "g"
  def signature(:unix_fd),     do: "h"
  def signature(:variant),     do: "v"
  def signature(%DBux.Value{type: type}), do: signature(type)

  def signature({:array, [subtype]}), do: "a" <> signature(subtype)
  def signature(%DBux.Value{type: :array, subtype: [subtype]}), do: signature({:array, [subtype]})

  def signature({:struct, subtypes}) when is_list(subtypes), do: "(" <> Enum.map(subtypes, fn(subtype) -> signature(subtype) end) <> ")"
  def signature(%DBux.Value{type: :struct, subtype: subtypes}) when is_list(subtypes), do: signature({:struct, subtypes})

  def signature({:dict_entry, subtypes}) when is_list(subtypes), do: "{" <> Enum.map(subtypes, fn(subtype) -> signature(subtype) end) <> "}"
  def signature(%DBux.Value{type: :dict_entry, subtype: subtypes}) when is_list(subtypes), do: signature({:dict_entry, subtypes})


  @doc """
  Returns atom that contains atom identifying type.

  Reverse function is `signature/1`.
  """
  @spec type(String.t) :: simple_type | :variant
  def type("y"), do: :byte
  def type("b"), do: :boolean
  def type("n"), do: :int16
  def type("q"), do: :uint16
  def type("i"), do: :int32
  def type("u"), do: :uint32
  def type("x"), do: :int64
  def type("t"), do: :uint64
  def type("d"), do: :double
  def type("s"), do: :string
  def type("o"), do: :object_path
  def type("g"), do: :signature
  def type("h"), do: :unix_fd
  def type("v"), do: :variant


  @doc """
  Parses signature in D-Bus format and returns it as a nested list in which
  simple types are represented as atoms and container types as tuples.

  For example, "yba{s(ui)}" will become `[:byte, :boolean, {:array, [{:dict, [:string, {:struct, [:uint32, :int32]}]}]}]`.

  First of all, it is much more convenient to have such structure if you want
  to recursively parse signature in Elixir, so it is used internally while
  demarshalling messages. It can also serve as validator for signatures.

  It returns `{:ok, list}` in case of success, `{:error, reason}` otherwise.

  It does most of the checks from the specification, but it does not check
  for dicts constraints at the moment.
  """
  @spec type_from_signature(String.t) :: list_of_types
  def type_from_signature(""), do: {:ok, []}
  def type_from_signature(signature) when is_binary(signature) do
    parse(signature, [])
  end


  @doc """
  Returns alignment size for given D-Bus type.
  """
  @spec align_size(simple_type_name | container_type_name) :: number
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
  def align_size({subtype_major, _subtype_minor}), do: align_size(subtype_major)


  # Computes padding size for container types.
  # It just takes container type, and ignores inner type.
  @doc false
  def compute_padding_size(length, type) when is_tuple(type) do
    {subtype_major, _} = type
    compute_padding_size(length, subtype_major)
  end


  # Computes padding size for a type, given data length and type name.
  @doc false
  def compute_padding_size(length, type) when is_atom(type) do
    compute_padding_size(length, DBux.Type.align_size(type))
  end


  # Computes padding size for a type, given data length and target padding.
  @doc false
  def compute_padding_size(length, align) when is_number(align) do
    padding = rem(length, align)

    case padding do
      0 -> 0
      _ -> align - padding
    end
  end


  # ------ TOP LEVEL ------


  # Top level: End of signature, return
  defp parse(<< >>, acc) do
    {:ok, acc}
  end


  # Top level: Enter inner recurrence for struct
  defp parse(<< "(", rest :: binary >>, acc) do
    case parse_struct(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        parse(rest_after_parse, acc ++ [value_parsed])

      {:error, reason} ->
        {:error, reason}
    end
  end


  # Top level: Got struct closing token but it wasn't opened
  defp parse(<< ")", _rest :: binary >>, _acc) do
    {:error, {:badsignature, :unmatchedstruct}}
  end


  # Top level: Attempt to enter inner recurrence for dict without enclosing array
  defp parse(<< "{", _rest :: binary >>, _acc) do
    {:error, {:badsignature, :unwrappeddict}}
  end


  # Top level: Got dict closing token but it wasn't opened
  defp parse(<< "}", _rest :: binary >>, _acc) do
    {:error, {:badsignature, :unmatcheddict}}
  end


  # Top level: Enter inner recurrence for array
  defp parse(<< "a", rest :: binary >>, acc) do
    case parse_array(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        parse(rest_after_parse, acc ++ [value_parsed])

      {:error, reason} ->
        {:error, reason}
    end
  end



  # Top level: Simple types
  defp parse(<< head :: binary-size(1), rest :: binary >>, acc) do
    parse(rest, acc ++ [type(head)])
  end


  # ------ STRUCT ------


  # Within struct: Enter inner recurrence for another struct
  defp parse_struct(<< "(", rest :: binary >>, acc) do
    case parse_struct(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        parse_struct(rest_after_parse, acc ++ [value_parsed])

      {:error, reason} ->
        {:error, reason}
    end
  end


  # Within struct: Closing empty struct
  defp parse_struct(<< ")", _rest :: binary >>, []) do
    {:error, {:badsignature, :emptystruct}}
  end


  # Within struct: Closing non-empty struct, return
  defp parse_struct(<< ")", rest :: binary >>, acc) do
    {:ok, {:struct, acc}, rest}
  end


  # Within struct: Attempt to enter inner recurrence for dict without enclosing array
  defp parse_struct(<< "{", _rest :: binary >>, _acc) do
    {:error, {:badsignature, :unwrappeddict}}
  end


  # Within struct: Got dict closing token but it wasn't opened
  defp parse_struct(<< "}", _rest :: binary >>, _acc) do
    {:error, {:badsignature, :unmatcheddict}}
  end


  # Within struct: Enter inner recurrence for array
  defp parse_struct(<< "a", rest :: binary >>, acc) do
    case parse_array(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        parse_struct(rest_after_parse, acc ++ [value_parsed])

      {:error, reason} ->
        {:error, reason}
    end
  end


  # Within struct: Struct has no contents
  defp parse_struct(<< >>, _acc) do
    {:error, {:badsignature, :unmatchedstruct}}
  end


  # Within struct: Simple types
  defp parse_struct(<< head :: binary-size(1), rest :: binary >>, acc) do
    parse_struct(rest, acc ++ [type(head)])
  end


  # ------ DICT ------


  # Within dict: Attempt to enter inner recurrence for dict without enclosing array
  defp parse_dict(<< "{", _rest :: binary >>, _acc) do
    {:error, {:badsignature, :unwrappeddict}}
  end


  # Within dict: Closing empty dict
  defp parse_dict(<< "}", _rest :: binary >>, []) do
    {:error, {:badsignature, :emptydict}}
  end


  # Within dict: Closing non-empty dict, return
  defp parse_dict(<< "}", rest :: binary >>, acc) do
    {:ok, {:dict, acc}, rest}
  end


  # Within dict: Enter inner recurrence for struct
  defp parse_dict(<< "(", rest :: binary >>, acc) do
    case parse_struct(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        parse_dict(rest_after_parse, acc ++ [value_parsed])

      {:error, reason} ->
        {:error, reason}
    end
  end


  # Within dict: Got struct closing token but it wasn't opened
  defp parse_dict(<< ")", _rest :: binary >>, _acc) do
    {:error, {:badsignature, :unmatchedstruct}}
  end


  # Within dict: Enter inner recurrence for array
  defp parse_dict(<< "a", rest :: binary >>, acc) do
    case parse_array(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        parse_dict(rest_after_parse, acc ++ [value_parsed])

      {:error, reason} ->
        {:error, reason}
    end
  end


  # Within dict: Dict has no contents
  defp parse_dict(<< >>, _acc) do
    {:error, {:badsignature, :unmatcheddict}}
  end


  # Within dict: Simple types
  defp parse_dict(<< head :: binary-size(1), rest :: binary >>, acc) do
    parse_dict(rest, acc ++ [type(head)])
  end


  # ------ ARRAY ------


  # Within array: Enter inner recurrence for struct
  defp parse_array(<< "(", rest :: binary >>, acc) do
    case parse_struct(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        {:ok, {:array, acc ++ [value_parsed]}, rest_after_parse}

      {:error, reason} ->
        {:error, reason}
    end
  end


  # Within array: Enter inner recurrence for dict
  defp parse_array(<< "{", rest :: binary >>, acc) do
    case parse_dict(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        {:ok, {:array, acc ++ [value_parsed]}, rest_after_parse}

      {:error, reason} ->
        {:error, reason}
    end
  end


  # Within array: Got struct closing token but it wasn't opened
  defp parse_array(<< ")", _rest :: binary >>, _acc) do
    {:error, {:badsignature, :unmatchedstruct}}
  end


  # Within array: Got dict closing token but it wasn't opened
  defp parse_array(<< "}", _rest :: binary >>, _acc) do
    {:error, {:badsignature, :unmatcheddict}}
  end


  # Within array: Enter inner recurrence for another array
  defp parse_array(<< "a", rest :: binary >>, acc) do
    case parse_array(rest, []) do
      {:ok, value_parsed, rest_after_parse} ->
        parse_array(rest_after_parse, acc ++ [value_parsed])

      {:error, reason} ->
        {:error, reason}
    end
  end


  # Within array: Empty array
  defp parse_array(<< >>, []) do
    {:error, {:badsignature, :emptyarray}}
  end


  # Within array: Container types, return
  defp parse_array(<< >>, acc) do
    {:ok, {:array, acc}, << >>}
  end


  # Within array: Simple types, return
  defp parse_array(<< head :: binary-size(1), rest :: binary >>, acc) do
    {:ok, {:array, acc ++ [type(head)]}, rest}
  end
end
