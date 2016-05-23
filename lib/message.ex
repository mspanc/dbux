defmodule DBux.Message do
  defstruct type: nil, path: nil, destination: nil, interface: nil, member: nil, error_name: nil, serial: nil, values: [], signature: nil
  @type t :: %DBux.Message{type: :method_call | :method_return | :error | :signal, serial: number, path: String.t, destination: String.t, interface: String.t, member: String.t, error_name: String.t, values: [] | [%DBux.Value{}], signature: String.t}


  @spec add_value(%DBux.Message{}, %DBux.Value{}) :: %DBux.Message{}
  def add_value(message, value) when is_map(message) and is_map(value) do
    %{message | values: message[:values] ++ [value]}
  end


  def method_call(serial, path, interface, member, values \\ [], destination \\ nil) do
    %DBux.Message{serial: serial, type: :method_call, path: path, interface: interface, member: member, values: values, destination: destination}
  end


  def signal(serial, path, interface, member, values \\ []) do
    %DBux.Message{serial: serial, type: :signal, path: path, interface: interface, member: member, values: values}
  end


  @spec marshall(%DBux.Message{}, :little_endian | :big_endian) :: Bitstring
  def marshall(message, endianness \\ :little_endian) when is_map(message) and is_atom(endianness) do
    # byte
    #	Endianness flag; ASCII 'l' for little-endian or ASCII 'B' for big-endian.
    # Both header and body are in this endianness.
    header_endianness = case endianness do
      :little_endian ->
        <<"l">>
      :big_endian ->
        <<"B">>
    end


    # byte
    # Message type. Unknown types must be ignored. Currently-defined types
    # are described below.
    header_message_type = case message.type do
      :method_call ->
        <<1>>
      :method_return ->
        <<2>>
      :error ->
        <<3>>
      :signal ->
        <<4>>
    end


    # byte
    # Bitwise OR of flags. Unknown flags must be ignored. Currently-defined
    # flags are described below.
    header_flags = <<0>> # TODO So far we do not support any flags


    # byte
    # Major protocol version of the sending application. If the major protocol
    # version of the receiving application does not match, the applications will not
    # be able to communicate and the D-Bus connection must be disconnected.
    # The major protocol version for this version of the specification is 1.
    header_protocol = <<1>>


    # uint32
    # Length in bytes of the message body, starting from the end of the header.
    # The header ends after its alignment padding to an 8-boundary.
    #
    header_body_length = %DBux.Value{type: :uint32, value: 0} |> DBux.Value.marshall(endianness)
    # FIXME


    # uint32
    # The serial of this message, used as a cookie by the sender to identify
    # the reply corresponding to this request. This must not be zero.
    header_serial = %DBux.Value{type: :uint32, value: message.serial} |> DBux.Value.marshall(endianness)


    # ARRAY of STRUCT of (BYTE,VARIANT)
    # An array of zero or more header fields where the byte is the field code,
    # and the variant is the field value. The message type determines which
    # fields are required.
    header_fields_value = case message.type do
      :method_call ->
        case message.interface do
          nil ->
            [
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 1}, %DBux.Value{type: :object_path, value: message.path}]},
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 3}, %DBux.Value{type: :string, value: message.member}]}
            ]

          _ ->
            [
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 1}, %DBux.Value{type: :object_path, value: message.path}]},
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 2}, %DBux.Value{type: :string, value: message.interface}]},
              %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 3}, %DBux.Value{type: :string, value: message.member}]}
            ]
        end

      :method_return ->
        [
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 5}, %DBux.Value{type: :uint32, value: message.reply_serial}]}
        ]

      :signal ->
        [
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 1}, %DBux.Value{type: :object_path, value: message.path}]},
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 2}, %DBux.Value{type: :string, value: message.interface}]},
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 3}, %DBux.Value{type: :string, value: message.member}]}
        ]

      :error ->
        [
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 4}, %DBux.Value{type: :string, value: message.error_name}]},
          %DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 5}, %DBux.Value{type: :uint32, value: message.reply_serial}]}
        ]
    end

    header_fields_value = case message.destination do
      nil ->
        header_fields_value

      _ ->
        header_fields_value ++ [%DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 6}, %DBux.Value{type: :string, value: message.destination}]}]
    end

    header_fields_value = case message.signature do
      nil ->
        header_fields_value

      _ ->
        header_fields_value ++ [%DBux.Value{type: :struct, subtype: [:byte, :variant], value: [%DBux.Value{type: :byte, value: 8}, %DBux.Value{type: :signature, value: message.signature}]}]
    end

    header_fields = %DBux.Value{type: :array, subtype: :struct, value: header_fields_value} |> DBux.Value.marshall(endianness)

    header_endianness <> header_message_type <> header_flags <> header_protocol <> header_body_length <> header_serial <> header_fields |> DBux.Value.align(8)
  end
end
