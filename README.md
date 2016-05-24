# DBux
[![Build Status](https://travis-ci.org/mspanc/dbux.svg?branch=master)](https://travis-ci.org/mspanc/dbux)

DBux provides bindings for [D-Bus](http://dbus.freedesktop.org) IPC
protocol for the [Elixir](http://elixir-lang.org) programming language.

## Project aims

DBux's aim is to provide low-level GenServer-like pattern to handle interaction
with D-Bus daemon.

It is not going to provide high-level proxy that will magically map
objects/interfaces exported over D-Bus to data structures used in your application.
In my opinion it's a task for an another abstraction layer (read: another project
built on top of DBux).

At the beginning it's going to provide only functionality needed to act as
a client. Exporting interfaces/objects may be added later.

## Status

Project in the early stage of development. API may change without prior warning.

# Sample Usage

```elixir
defmodule MyClientBus do
  use DBux.Bus

  def start_link(opts \\ []) do
    DBux.start_link(__MODULE__, DBux.Transport.TCP, %{host: "example.com", port: 8888}, DBux.Auth.Anonymous, %{})
  end
end


defmodule MyExampleApp do
  def send_message_call do
    {:ok, bus} = MyClientBus.start_link
    {:ok, serial} = DBux.Bus.do_method_call(bus, "/org/freedesktop/DBus", "org.freedesktop.DBus", "Hello", [], "org.freedesktop.DBus")
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
