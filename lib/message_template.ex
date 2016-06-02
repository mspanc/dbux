defmodule DBux.MessageTemplate do
  @moduledoc """
  This module contains helper functions that can be used to easily build
  well-known messages.
  """


  @doc """
  Builds standard method call to org.freedesktop.DBus.Hello.
  """
  @spec hello(DBux.Serial.t) :: %DBux.Message{}
  def hello(serial \\ 0) when is_number(serial) do
    DBux.Message.build_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "Hello", "", [], "org.freedesktop.DBus", serial)
  end


  @doc """
  Builds standard method call to org.freedesktop.DBus.RequestName.
  """
  @spec request_name(String.t, number, DBux.Serial.t) :: %DBux.Message{}
  def request_name(name, flags \\ 0, serial \\ 0) when is_number(serial) and is_binary(name) and is_number(flags) do
    DBux.Message.build_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "RequestName", "su", [
      %DBux.Value{type: :string, value: name},
      %DBux.Value{type: :uint32, value: flags}
    ], "org.freedesktop.DBus", serial)
  end


  @doc """
  Builds standard method call to org.freedesktop.DBus.AddMatch.
  """
  @spec add_match(DBux.Message.message_type, String.t, String.t, String.t, String.t, String.t, String.t, [] | [String.t], [] | [String.t], String.t, boolean, DBux.Serial.t) :: %DBux.Message{}
  def add_match(type \\ nil, sender \\ nil, interface \\ nil, member \\ nil, path \\ nil, path_namespace \\ nil, destination \\ nil, string_matches \\ [], path_matches \\ [], arg0namespace \\ nil, eavesdrop \\ nil, serial \\ 0) when is_number(serial) do
    filter = []

    filter = if !is_nil(type),           do: filter ++ ["type='#{type}'"],                     else: filter
    filter = if !is_nil(sender),         do: filter ++ ["sender='#{sender}'"],                 else: filter
    filter = if !is_nil(interface),      do: filter ++ ["interface='#{interface}'"],           else: filter
    filter = if !is_nil(member),         do: filter ++ ["member='#{member}'"],                 else: filter
    filter = if !is_nil(path),           do: filter ++ ["path='#{path}'"],                     else: filter
    filter = if !is_nil(path_namespace), do: filter ++ ["path_namespace='#{path_namespace}'"], else: filter
    filter = if !is_nil(destination),    do: filter ++ ["destination='#{destination}'"],       else: filter
    filter = if !is_nil(arg0namespace),  do: filter ++ ["arg0namespace='#{arg0namespace}'"],   else: filter
    filter = if !is_nil(eavesdrop),      do: filter ++ ["eavesdrop='#{eavesdrop}'"],           else: filter

    # TODO add string escaping
    # TODO add support for string_matches
    # TODO add support for path_matches

    DBux.Message.build_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "AddMatch", "s", [
      %DBux.Value{type: :string, value: Enum.join(filter, ",")},
    ], "org.freedesktop.DBus", serial)
  end


  @doc """
  Builds standard method call to org.freedesktop.DBus.ListNames.
  """
  @spec list_names(DBux.Serial.t) :: %DBux.Message{}
  def list_names(serial \\ 0) when is_number(serial) do
    DBux.Message.build_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "ListNames", "", [], "org.freedesktop.DBus", serial)
  end
end
