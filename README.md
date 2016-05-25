# DBux
[![Build Status](https://travis-ci.org/mspanc/dbux.svg?branch=master)](https://travis-ci.org/mspanc/dbux)

DBux provides bindings for [D-Connection](http://dbus.freedesktop.org) IPC
protocol for the [Elixir](http://elixir-lang.org) programming language.

## Project aims

DBux's aim is to provide low-level GenServer-like pattern to handle interaction
with D-Connection daemon.

It is not going to provide high-level proxy that will magically map
objects/interfaces exported over D-Connection to data structures used in your application.
In my opinion it's a task for an another abstraction layer (read: another project
built on top of DBux).

At the beginning it's going to provide only functionality needed to act as
a client. Exporting interfaces/objects may be added later.

## Status

Project in the early stage of development. API may change without prior warning.

# Sample Usage

```elixir
defmodule MyClientConnection do
  use DBux.Connection

  def start_link(opts \\ []) do
    DBux.Connection.start_link(__MODULE__,
      DBux.Transport.TCP, %{host: "example.com", port: 8888},
      DBux.Auth.Anonymous, %{})
  end


  def init(_transport_mod, _transport_opts, _auth_mod, _auth_opts) do
    {:ok, %{}}
  end
end


defmodule MyExampleApp do
  def send_method_call do
    {:ok, connection} = MyClientConnection.start_link
    {:ok, serial} = DBux.Connection.do_method_call(connection, "/org/freedesktop/DBus", "org.freedesktop.DBus", "Hello", [], "org.freedesktop.DBus")
  end


  def handle_method_call(serial, path, member, interface, values, state) do
    # TODO
    {:noreply, state}
  end


  def handle_method_return(serial, reply_serial, state) do
    # TODO
    {:noreply, state}
  end


  def handle_error(serial, reply_serial, error_name, state) do
    # TODO
    {:noreply, state}
  end


  def handle_signal(serial, path, member, interface, state) do
    # TODO
    {:noreply, state}
  end
end
```

# Authors

Marcin Lewandowski <marcin@saepia.net>

# Credits

Project is heavily inspired by [Connection](https://hex.pm/packages/connection)
and [ruby-dbus](https://github.com/mvidner/ruby-dbus). It may contain parts of
code that come from these projects.

# License

MIT
