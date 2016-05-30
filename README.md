# DBux
[![Build Status](https://travis-ci.org/mspanc/dbux.svg?branch=master)](https://travis-ci.org/mspanc/dbux)
[![Coverage Status](https://coveralls.io/repos/github/mspanc/dbux/badge.svg?branch=master)](https://coveralls.io/github/mspanc/dbux?branch=master)

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

## Status

Project in production use in at least one big app :)

# Sample Usage

An example `DBux.Connection` process:

```elixir
defmodule MyApp.Bus do
  require Logger
  use DBux.Connection

  def start_link(options \\ []) do
    DBux.Connection.start_link(__MODULE__, "myserver.example.com")
  end

  def init(hostname) do
    Logger.debug("Init, hostname = #{hostname}")
    initial_state = %{request_name_serial: nil}
    {:ok, "tcp:host=#{hostname},port=8888", [:anonymous], initial_state}
  end

  def request_name(proc) do
    DBux.Connection.call(proc, :request_name)
  end

  @doc false
  def handle_up(state) do
    Logger.info("Up")
    {:noreply, state}
  end

  @doc false
  def handle_down(state) do
    Logger.warn("Down")
    {:noreply, state}
  end

  @doc false
  def handle_method_return(_serial, reply_serial, _body, %{request_name_serial: request_name_serial} = state) do
    cond do
      reply_serial == request_name_serial ->
        Logger.info("Name acquired")
        {:noreply, %{state | request_name_serial: nil}}

      true ->
        {:noreply, state}
    end
  end

  @doc false
  def handle_error(_serial, reply_serial, error_name, _body, %{request_name_serial: request_name_serial} = state) do
    cond do
      reply_serial == request_name_serial ->
        Logger.warn("Failed te acquire name: #{error_name}")
        {:noreply, %{state | request_name_serial: nil}}

      true ->
        {:noreply, state}
    end
  end

  @doc false
  def handle_call(:request_name, state) do
    case DBux.Connection.do_method_call(self(),
      "/org/freedesktop/DBus",
      "org.freedesktop.DBus",
      "RequestName",
      [ %DBux.Value{type: :string, value: "com.example.dbux"},
        %DBux.Value{type: :uint32, value: 0} ],
      "org.freedesktop.DBus") do
      {:ok, serial} ->
        {:reply, :ok, %{state | request_name_serial: serial}}

      {:error, reason} ->
        Logger.warn("Unable to request name, reason = #{inspect(reason)}")
        {:reply, {:error, reason} state}
    end
  end
end
```

And of the accompanying process that can control the connection:

```elixir
defmodule MyApp.Core do
  def do_the_stuff do
    {:ok, connection} = MyApp.Bus.start_link
    {:ok, serial} = MyApp.Bus.request_name(connection)
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
