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
    DBux.Message.build_method_call(serial, "/org/freedesktop/DBus", "org.freedesktop.DBus", "Hello", [], "org.freedesktop.DBus")
  end


  @doc """
  Builds standard method call to org.freedesktop.DBus.RequestName.
  """
  @spec request_name(String.t, number, DBux.Serial.t) :: %DBux.Message{}
  def request_name(name, flags \\ 0, serial \\ 0) when is_number(serial) and is_binary(name) and is_number(flags) do
    DBux.Message.build_method_call(serial, "/org/freedesktop/DBus", "org.freedesktop.DBus", "RequestName", [
      %DBux.Value{type: :string, value: name},
      %DBux.Value{type: :uint32, value: flags}
    ], "org.freedesktop.DBus")
  end
end
