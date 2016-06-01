defmodule DBux.Message do
  defstruct \
    message_type: nil,
    flags:        0,
    path:         nil,
    destination:  nil,
    interface:    nil,
    member:       nil,
    error_name:   nil,
    reply_serial: nil,
    serial:       nil,
    body:         [],
    signature:    "",
    sender:       nil,
    unix_fds:     nil

  @type message_type :: :method_call | :method_return | :error | :signal

  @type t :: %DBux.Message{
    message_type: message_type,
    serial:       DBux.Serial.t,
    flags:        number,
    path:         String.t,
    destination:  String.t,
    interface:    String.t,
    member:       String.t,
    error_name:   String.t,
    body:         DBux.Value.list_of_values,
    signature:    String.t,
    sender:       String.t,
    unix_fds:     number,
    reply_serial: number}

  @protocol_version 1
  @message_header_signature "yyyyuua(yv)"

  @default_endianness (case << 1 :: size(4)-unit(8)-native >> do
    << 1 :: size(4)-unit(8)-big >> ->
      :big_endian
    << 1 :: size(4)-unit(8)-little >> ->
      :little_endian
  end)


  @doc """
  Creates DBux.Message with attributes appropriate for method call.
  """
  @spec build_method_call(String.t, String.t, DBux.Value.list_of_values, String.t | nil, DBux.Serial.t) :: %DBux.Message{}
  def build_method_call(path, interface, member, body \\ [], destination \\ nil, serial \\ 0) when is_number(serial) and is_binary(path) and is_binary(interface) and is_list(body) and (is_binary(destination) or is_nil(destination)) do
    %DBux.Message{serial: serial, message_type: :method_call, path: path, interface: interface, member: member, body: body, destination: destination}
  end


  @doc """
  Creates DBux.Message with attributes appropriate for signal.
  """
  @spec build_signal(String.t, String.t, String.t,  DBux.Value.list_of_values, DBux.Serial.t) :: %DBux.Message{}
  def build_signal(path, interface, member, body \\ [], serial \\ 0) when is_number(serial) and is_binary(path) and is_binary(interface) and is_list(body) do
    %DBux.Message{serial: serial, message_type: :signal, path: path, interface: interface, member: member, body: body}
  end


  @doc """
  Creates DBux.Message with attributes appropriate for method return.
  """
  @spec build_method_return(DBux.Serial.t, String.t, DBux.Value.list_of_values, DBux.Serial.t) :: %DBux.Message{}
  def build_method_return(reply_serial, destination, body \\ [], serial \\ 0) when is_number(serial) and is_number(reply_serial) and is_list(body) and is_binary(destination) do
    %DBux.Message{serial: serial, message_type: :method_return, reply_serial: reply_serial, body: body, destination: destination}
  end


  @doc """
  Creates DBux.Message with attributes appropriate for error.
  """
  @spec build_error(DBux.Serial.t, String.t, DBux.Value.list_of_values, DBux.Serial.t) :: %DBux.Message{}
  def build_error(reply_serial, error_name, destination, body \\ [], serial \\ 0) when is_number(serial) and is_number(reply_serial) and is_binary(error_name) and is_list(body) and is_binary(destination) do
    %DBux.Message{serial: serial, message_type: :error, reply_serial: reply_serial, error_name: error_name, body: body, destination: destination}
  end


  @doc """
  Serializes DBux.Message into bitstream using given endianness.

  TODO describe return values
  """
  @spec marshall(%DBux.Message{}, :little_endian | :big_endian) :: Bitstring
  def marshall(message, endianness \\ @default_endianness) when is_map(message) and is_atom(endianness) do
    # byte
    #	Endianness flag; ASCII 'l' for little-endian or ASCII 'B' for big-endian.
    # Both header and body are in this endianness.
    header_endianness_bitstring = case endianness do
      :little_endian ->
        << "l" >>
      :big_endian ->
        << "B" >>
    end


    # byte
    # Message type. Unknown types must be ignored. Currently-defined types
    # are described below.
    header_message_type_bitstring = case message.message_type do
      :method_call ->
        << 1 >>
      :method_return ->
        << 2 >>
      :error ->
        << 3 >>
      :signal ->
        << 4 >>
    end


    # byte
    # Bitwise OR of flags. Unknown flags must be ignored. Currently-defined
    # flags are described below.
    header_flags_bitstring = << 0 >> # TODO So far we do not support any flags


    # byte
    # Major protocol version of the sending application. If the major protocol
    # version of the receiving application does not match, the applications will not
    # be able to communicate and the D-Bus connection must be disconnected.
    # The major protocol version for this version of the specification is 1.
    header_protocol_bitstring = << @protocol_version >>


    # uint32
    # Length in bytes of the message body, starting from the end of the header.
    # The header ends after its alignment padding to an 8-boundary.
    #

    {:ok, {body_bitstring, body_signature}} = DBux.Protocol.marshall_bitstring(message.body, endianness)
    {:ok, {body_length, _}} = %DBux.Value{type: :uint32, value: byte_size(body_bitstring)} |> DBux.Value.marshall(endianness)


    # uint32
    # The serial of this message, used as a cookie by the sender to identify
    # the reply corresponding to this request. This must not be zero.
    {:ok, {header_serial_bitstring, _}} = %DBux.Value{type: :uint32, value: message.serial} |> DBux.Value.marshall(endianness)


    # ARRAY of STRUCT of (BYTE,VARIANT)
    # An array of zero or more header fields where the byte is the field code,
    # and the variant is the field value. The message type determines which
    # fields are required.
    header_fields_value = []

    header_fields_value = case body_signature do
      "" ->
        header_fields_value

      _ ->
        header_fields_value ++ [%DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 8}, %DBux.Value{type: :variant, subtype: :signature, value: body_signature}]}]
    end


    header_fields_value = case message.message_type do
      :method_call ->
        case message.interface do
          nil ->
            header_fields_value ++ [
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 1}, %DBux.Value{type: :variant, subtype: :object_path, value: message.path}]},
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 3}, %DBux.Value{type: :variant, subtype: :string, value: message.member}]}
            ]

          _ ->
            header_fields_value ++ [
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 1}, %DBux.Value{type: :variant, subtype: :object_path, value: message.path}]},
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 3}, %DBux.Value{type: :variant, subtype: :string, value: message.member}]},
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 2}, %DBux.Value{type: :variant, subtype: :string, value: message.interface}]}
            ]
        end

      :method_return ->
        header_fields_value ++ [
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 5}, %DBux.Value{type: :variant, subtype: :uint32, value: message.reply_serial}]}
        ]

      :signal ->
        header_fields_value ++ [
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 1}, %DBux.Value{type: :variant, subtype: :object_path, value: message.path}]},
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 2}, %DBux.Value{type: :variant, subtype: :string, value: message.interface}]},
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 3}, %DBux.Value{type: :variant, subtype: :string, value: message.member}]}
        ]

      :error ->
        header_fields_value ++ [
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 4}, %DBux.Value{type: :variant, subtype: :string, value: message.error_name}]},
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 5}, %DBux.Value{type: :variant, subtype: :uint32, value: message.reply_serial}]}
        ]
    end

    header_fields_value = case message.destination do
      nil ->
        header_fields_value

      _ ->
        header_fields_value ++ [%DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 6}, %DBux.Value{type: :variant, subtype: :string, value: message.destination}]}]
    end

    header_fields_value = case message.sender do
      nil ->
        header_fields_value

      _ ->
        header_fields_value ++ [%DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 7}, %DBux.Value{type: :variant, subtype: :string, value: message.sender}]}]
    end

    header_fields_value = case message.unix_fds do
      nil ->
        header_fields_value

      _ ->
        header_fields_value ++ [%DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 9}, %DBux.Value{type: :variant, subtype: :uint32, value: message.unix_fds}]}]
    end

    {:ok, {header_fields_bitstring, _}} = %DBux.Value{type: :array, subtype: [:struct], value: header_fields_value} |> DBux.Value.marshall(endianness)

    {:ok, {message_bitstring, _padding}} = header_endianness_bitstring <>
      header_message_type_bitstring <>
      header_flags_bitstring <>
      header_protocol_bitstring <>
      body_length <>
      header_serial_bitstring <>
      header_fields_bitstring
      |> DBux.Value.align(8)

    {:ok, message_bitstring <> body_bitstring}
  end


  @doc """
  Parses bitstream into DBux.Message.

  First byte of the bitstream must be first byte of a message.

  Returns `{:ok, message, rest}` in case of success, where message is
  a DBux.Message and rest is a remaining part of the given bitstream.

  If not enough data was given it returns `{:error, :bitstring_too_short}`.
  """
  @spec unmarshall(Bitstring, boolean) :: {:ok, %DBux.Message{}, Bitstring} | {:error, any}
  def unmarshall(<< >>, _unwrap_values), do: {:error, :bitstring_too_short}
  def unmarshall(bitstring, unwrap_values) when is_binary(bitstring) do
    << endianness_bitstring, _rest :: binary >> = bitstring

    endianness = case endianness_bitstring do
      108 -> :little_endian
      66  -> :big_endian
    end

    case DBux.Protocol.unmarshall_bitstring(bitstring, endianness, @message_header_signature, true) do
      {:ok, {[_endianness_raw, message_type_raw, flags, @protocol_version, body_length, serial, header_fields], rest}} ->
        if byte_size(rest) < body_length do
          {:error, :bitstring_too_short}

        else
          << body :: binary-size(body_length), rest :: binary >> = rest

          message_type = case message_type_raw do
            1 -> :method_call
            2 -> :method_return
            3 -> :error
            4 -> :signal
          end

          message = %DBux.Message{message_type: message_type, flags: flags, serial: serial}

          message = Enum.reduce(header_fields, message, fn({header_field_type, header_field_value}, acc) ->
            message_key = case header_field_type do
              1 -> :path
              2 -> :interface
              3 -> :member
              4 -> :error_name
              5 -> :reply_serial
              6 -> :destination
              7 -> :sender
              8 -> :signature
              9 -> :unix_fds
            end

            Map.put(acc, message_key, header_field_value)
          end)

          case DBux.Protocol.unmarshall_bitstring(body, endianness, message.signature, unwrap_values) do
            {:ok, {body, _}} -> # Drop the remaining padding
              {:ok, {message |> Map.put(:body, body), rest}}

            {:error, reason} ->
              {:error, reason}
          end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
