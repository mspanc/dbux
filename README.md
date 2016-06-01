# DBux
[![Build Status](https://travis-ci.org/mspanc/dbux.svg?branch=master)](https://travis-ci.org/mspanc/dbux)
[![Coverage Status](https://coveralls.io/repos/github/mspanc/dbux/badge.svg?branch=master)](https://coveralls.io/github/mspanc/dbux?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/dbux.svg)](https://hex.pm/packages/dbux)
[![Hex.pm](https://img.shields.io/hexpm/dt/dbux.svg)](https://hex.pm/packages/dbux)

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
a client. Acting as a server may be added later.

## Versioning

Project follows [Semantic Versioning](http://semver.org/).

## Status

Project in production use in at least one big app :) However, some things are
still not implemented:

* Marshalling variants that contain container types
* Handling message timeouts
* Handling introspection calls and other generic D-Bus methods
* Other transports than TCP
* Other authentication methods than anonymous

# Installation

Add dependency to your `mix.exs`:

```elixir
defp deps do
  [{:dbux, "~> 1.0.0"}]
end
```

# Sample Usage

An example `DBux.PeerConnection` process:

```elixir
defmodule MyApp.Bus do
  require Logger
  use DBux.PeerConnection

  @request_name_message_id :request_name
  @add_match_message_id    :add_match

  @introspection """
  <!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
   "http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
  <node name="/com/example/sample_object">
    <interface name="com.example.SampleInterface">
      <method name="Frobate">
        <arg name="foo" type="i" direction="in"/>
        <arg name="bar" type="s" direction="out"/>
        <arg name="baz" type="a{us}" direction="out"/>
        <annotation name="org.freedesktop.DBus.Deprecated" value="true"/>
      </method>
      <method name="Bazify">
        <arg name="bar" type="(iiu)" direction="in"/>
        <arg name="bar" type="v" direction="out"/>
      </method>
      <method name="Mogrify">
        <arg name="bar" type="(iiav)" direction="in"/>
      </method>
      <signal name="Changed">
        <arg name="new_value" type="b"/>
      </signal>
      <property name="Bar" type="y" access="readwrite"/>
    </interface>
    <node name="child_of_sample_object"/>
    <node name="another_child_of_sample_object"/>
  </node>
  """

  def start_link(hostname, options \\ []) do
    DBux.PeerConnection.start_link(__MODULE__, hostname, options)
  end

  def init(hostname) do
    initial_state = %{hostname: hostname}

    {:ok, "tcp:host=" <> hostname <> ",port=8888", [:anonymous], initial_state}
  end

  def handle_up(state) do
    Logger.info("Up")

    {:send, [
      DBux.Message.build_signal("/", "org.example.dbux.MyApp", "Connected", []),
      {@add_match_message_id,    DBux.MessageTemplate.add_match(:signal, nil, "org.example.dbux.OtherIface")},
      {@request_name_message_id, DBux.MessageTemplate.request_name("org.example.dbux.MyApp", 0x4)}
    ], state}
  end

  def handle_down(state) do
    Logger.warn("Down")
    {:backoff, 1000, state}
  end

  def handle_method_call(serial, sender, "/", "Introspect", "org.freedesktop.DBus.Introspectable", _body, _flags, state) do
    Logger.debug("Got Introspect call")

    {:send, [
      DBux.Message.build_method_return(serial, sender, [%DBux.Value{type: :string, value: @introspection}])
    ], state}
  end

  def handle_method_return(_serial, _sender, _reply_serial, _body, @request_name_message_id, state) do
    Logger.info("Name acquired")
    {:noreply, state}
  end

  def handle_method_return(_serial, _sender, _reply_serial, _body, @add_match_message_id, state) do
    Logger.info("Match added")
    {:noreply, state}
  end

  def handle_error(_serial, _sender, _reply_serial, error_name, _body, @request_name_message_id, state) do
    Logger.warn("Failed to acquire name: " <> error_name)
    {:noreply, state}
  end

  def handle_error(_serial, _sender, _reply_serial, error_name, _body, @add_match_message_id, state) do
    Logger.warn("Failed to add match: " <> error_name)
    {:noreply, state}
  end

  def handle_signal(_serial, _sender, _path, _member, "org.example.dbux.OtherIface", _body, state) do
    Logger.info("Got signal from OtherIface")
    {:noreply, state}
  end

  def handle_signal(_serial, _sender, _path, _member, _member, _body, state) do
    Logger.info("Got other signal")
    {:noreply, state}
  end
end

```

And of the accompanying process that can control the connection:

```elixir
defmodule MyApp.Core do
  def do_the_stuff do
    {:ok, connection} = MyApp.Bus.start_link("dbusserver.example.com")
  end
end
```

# Authors

Marcin Lewandowski <marcin@saepia.net>

# Debugging

If you encounter bugs, you may want to compile (not run, compile) the code with
`DBUX_DEBUG` environment variable set to any value.

# Contributing

You are welcome to open pull requests. Tests are mandatory.

# Credits

Project is heavily inspired by [Connection](https://hex.pm/packages/connection).

# License

MIT
