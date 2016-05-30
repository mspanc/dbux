defmodule DBux.Connection do
  @moduledoc """
  This module handles connection to the another D-Bus peer.

  At the moment it handles only connections to the buses.

  It basically allows to establish a connection and then send and receive messages.
  Its interface is intentionally quite low-level. You probably won't be able to
  use it properly without understanding how D-Bus protocol works.

  An example `DBux.Connection` process:

      defmodule MyApp.Bus do
        require Logger
        use DBux.Connection

        def start_link(options \\ []) do
          DBux.Connection.start_link(__MODULE__, "myserver.example.com")
        end

        def init(hostname) do
          Logger.debug("Init")
          initial_state = %{request_name_serial: nil}
          {:ok, "tcp:host=" <> hostname <> ",port=8888", [:anonymous], initial_state}
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
              Logger.warn("Failed te acquire name: " <> error_name)
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
            "Hello", [
              %DBux.Value{type: :string, value: "com.example.dbux"},
              %DBux.Value{type: :uint32, value: 0}
            ],
            "org.freedesktop.DBus") do
            {:ok, serial} ->
              {:reply, :ok, %{state | request_name_serial: serial}}

            {:error, reason} ->
              Logger.warn("Unable to request name, reason = " <> inspect(reason))
              {:reply, {:error, reason} state}
          end
        end
      end

  And of the accompanying process that can control the connection:

      defmodule MyApp.Core do
        def do_the_stuff do
          {:ok, connection} = MyApp.Bus.start_link
          {:ok, serial} = MyApp.Bus.request_name(connection)
        end
      end

  """

  require Logger
  use Connection

  @connect_timeout 5000
  @reconnect_timeout 5000

  @debug !is_nil(System.get_env("DBUX_DEBUG"))

  @doc """
  Called when Connection process is first started. `start_link/1` will block
  until it returns.

  The first argument will be the same as `mod_options` passed to `start_link/3`.

  Returning `{:ok, address, auth_mechanisms, state}` will cause `start_link/5`
  to return `{:ok, pid}` and the process to enter its loop with state `state`
  """
  @callback init(any) ::
    {:ok, String.t, [any], any}

  @doc """
  Called when connection is ready.

  Returning `{:noreply, state}` will cause to update state with `state`.
  """
  @callback handle_up(any) ::
    {:noreply, any}

  @doc """
  Called when connection is lost.

  Returning `{:noreply, state}` will cause to update state with `state`.
  """
  @callback handle_down(any) ::
    {:noreply, any}

  @doc """
  Called when we receive a method call.

  Returning `{:noreply, state}` will cause to update state with `state`.
  """
  @callback handle_method_call(DBux.Serial.t, String.t, String.t, String.t, DBux.Value.list_of_values, any) ::
    {:noreply, any}

  @doc """
  Called when we receive a method return.

  Returning `{:noreply, state}` will cause to update state with `state`.
  """
  @callback handle_method_return(DBux.Serial.t, DBux.Serial.t, DBux.Value.list_of_values, any) ::
    {:noreply, any}

  @doc """
  Called when we receive an error.

  Returning `{:noreply, state}` will cause to update state with `state`.
  """
  @callback handle_error(DBux.Serial.t, DBux.Serial.t, String.t, DBux.Value.list_of_values, any) ::
    {:noreply, any}

  @doc """
  Called when we receive a signal.

  Returning `{:noreply, state}` will cause to update state with `state`.
  """
  @callback handle_signal(DBux.Serial.t, String.t, String.t, String.t, DBux.Value.list_of_values, any) ::
    {:noreply, any}


  defmacro __using__(_) do
    quote location: :keep do
      @behaviour DBux.Connection

      # Default implementations

      @doc false
      def handle_up(state) do
        {:noreply, state}
      end

      @doc false
      def handle_down(state) do
        {:noreply, state}
      end

      @doc false
      def handle_method_call(_serial, _path, _member, _interface, _body, state) do
        {:noreply, state}
      end

      @doc false
      def handle_method_return(_serial, _reply_serial, _body, state) do
        {:noreply, state}
      end

      @doc false
      def handle_error(_serial, _reply_serial, _error_name, _body, state) do
        {:noreply, state}
      end

      @doc false
      def handle_signal(_serial, _path, _member, _interface, _body, state) do
        {:noreply, state}
      end

      defoverridable [
        handle_up: 1,
        handle_down: 1,
        handle_method_call: 6,
        handle_method_return: 4,
        handle_error: 5,
        handle_signal: 6]
    end
  end


  @doc """
  Connects to the bus run by a D-Bus daemon or other pper using given
  transport and authentication methods.

  `mod` is a module that will become a process, similarily how it happens
  in GenServer.

  `mod_options` are options that will be passed to `init/1`.

  `proc_options` are options that will be passed to underlying
  `GenServer.start_link` call, so they can contain global process name etc.

  It returns the same return value as `GenServer.start_link`.
  """
  @spec start_link(module, any, list) :: GenServer.on_start
  def start_link(mod, mod_options \\ nil, proc_options \\ []) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Start link: mod_options = #{inspect(mod_options)}, proc_options = #{inspect(proc_options)}")

    Connection.start_link(__MODULE__, {mod, mod_options}, proc_options)
  end


  @doc """
  Sends DBux.Message with attributes appropriate for method call.

  Returns `{:ok, serial}` on success.

  Returns `{:error, reason}` otherwise. Please note that error does not mean
  error reply over D-Bus, but internal application error.

  It is a synchronous call.
  """
  @spec send_method_call(pid, String.t, String.t, DBux.Value.list_of_values, String.t | nil) :: {:ok, DBux.Serial.t} | {:error, any}
  def send_method_call(bus, path, interface, member, body \\ [], destination \\ nil) when is_binary(path) and is_binary(interface) and is_list(body) and (is_binary(destination) or is_nil(destination)) do
    DBux.Connection.call(bus, {:dbux_send_message, DBux.Message.build_method_call(0, path, interface, member, body, destination)})
  end


  @doc """
  Sends DBux.Message with attributes appropriate for signal.

  Returns `{:ok, serial}` on success.

  Returns `{:error, reason}` otherwise. Please note that error does not mean
  error reply over D-Bus, but internal application error.

  It is a synchronous call.
  """
  @spec send_signal(pid, String.t, String.t, String.t, DBux.Value.list_of_values) :: {:ok, DBux.Serial.t} | {:error, any}
  def send_signal(bus, path, interface, member, body \\ []) when is_binary(path) and is_binary(interface) and is_list(body) do
    DBux.Connection.call(bus, {:dbux_send_message, DBux.Message.build_signal(0, path, interface, member, body)})
  end


  @doc """
  Sends DBux.Message with attributes appropriate for method return.

  Returns `{:ok, serial}` on success.

  Returns `{:error, reason}` otherwise. Please note that error does not mean
  error reply over D-Bus, but internal application error.

  It is a synchronous call.
  """
  @spec send_method_return(pid, DBux.Serial.t, DBux.Value.list_of_values) :: {:ok, DBux.Serial.t} | {:error, any}
  def send_method_return(bus, reply_serial, body \\ []) when is_number(reply_serial) and is_list(body) do
    DBux.Connection.call(bus, {:dbux_send_message, DBux.Message.build_method_return(0, reply_serial, body)})
  end


  @doc """
  Sends DBux.Message with attributes appropriate for error.

  Returns `{:ok, serial}` on success.

  Returns `{:error, reason}` otherwise. Please note that error does not mean
  error reply over D-Bus, but internal application error.

  It is a synchronous call.
  """
  @spec send_error(pid, DBux.Serial.t, String.t, DBux.Value.list_of_values) :: {:ok, DBux.Serial.t} | {:error, any}
  def send_error(bus, reply_serial, error_name, body \\ []) when is_number(reply_serial) and is_binary(error_name) and is_list(body) do
    DBux.Connection.call(bus, {:dbux_send_message, DBux.Message.build_error(0, reply_serial, error_name, body)})
  end


  @doc false
  def init({mod, mod_options}) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Init, mod = #{inspect(mod)}, mod_options = #{inspect(mod_options)}")

    {:ok, address, auth_mechanisms, mod_state} = mod.init(mod_options)
    {:ok, {transport_mod, transport_opts}} = DBux.Transport.get_module_for_address(address)
    {:ok, {auth_mod, auth_opts}} = DBux.Auth.get_module_for_method(hd(auth_mechanisms)) # FIXME support more mechanisms

    {:ok, transport_proc} = transport_mod.start_link(self(), transport_opts)
    {:ok, auth_proc}      = auth_mod.start_link(self(), auth_opts)
    {:ok, serial_proc}    = DBux.Serial.start_link()

    initial_state = %{
      mod:                 mod,
      mod_state:           mod_state,
      state:               :init,
      transport_mod:       transport_mod,
      transport_proc:      transport_proc,
      auth_mod:            auth_mod,
      auth_proc:           auth_proc,
      serial_proc:         serial_proc,
      unique_name:         nil,
      hello_serial:        nil,
      buffer:              << >>,
      unwrap_values:       true
    }

    {:connect, :init, initial_state}
  end


  @doc false
  def connect(_, %{transport_mod: transport_mod, transport_proc: transport_proc, auth_mod: auth_mod, auth_proc: auth_proc} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Connecting")
    case transport_mod.do_connect(transport_proc) do
      :ok ->
        if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Authenticating")
        case auth_mod.do_handshake(auth_proc, transport_mod, transport_proc) do
          :ok ->
            if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Sent authentication request")
            {:ok, %{state | state: :authenticating}}

          {:error, _} ->
            Logger.warn("[DBux.Connection #{inspect(self())}] Failed to send authentication request")
            {:backoff, @reconnect_timeout, %{state | state: :init}}
        end

      {:error, _} ->
        if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Failed to connect")
        {:backoff, @reconnect_timeout, %{state | state: :init}}
    end
  end


  @doc false
  def handle_call({:dbux_send_message, _message}, _sender, %{state: :init} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle call: send method call when not authenticated")
    {:reply, {:error, :not_authenticated}, state}
  end


  @doc false
  def handle_call({:dbux_send_message, message}, _sender, state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle call: send message when authenticated: message = #{inspect(message)}")
    case send_message(message, state) do
      {:ok, serial} ->
        {:reply, {:ok, serial}, state}

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to send method call: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  @doc false
  def handle_info(:dbux_authentication_succeeded, %{state: :authenticating, transport_mod: transport_mod, transport_proc: transport_proc} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: authentication succeeded")

    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Beginning message transmission")
    case transport_mod.do_begin(transport_proc) do
      :ok ->
        if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Began message transmission")

        if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Sending Hello")
        case send_message(DBux.Message.build_method_call(0, "/org/freedesktop/DBus", "org.freedesktop.DBus", "Hello", [], "org.freedesktop.DBus"), state) do
          {:ok, serial} ->
            {:noreply, %{state | state: :authenticated, hello_serial: serial}}

          {:error, reason} ->
            Logger.warn("[DBux.Connection #{inspect(self())}] Failed to send Hello: #{inspect(reason)}")
            {:noreply, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>}} # FIXME terminate, disconnect transport
        end

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to begin message transmission: #{inspect(reason)}")
        {:noreply, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>}} # FIXME terminate, disconnect transport
    end
  end


  @doc false
  def handle_info(:dbux_authentication_failed, %{state: :authenticating} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: authentication failed")
    {:noreply, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>}} # FIXME terminate, disconnect transport
  end


  @doc false
  def handle_info(:dbux_authentication_error, %{state: :authenticating} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: authentication error")
    {:noreply, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>}} # FIXME terminate, disconnect transport
  end


  @doc false
  def handle_info(:dbux_transport_down, state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: Transport down")
    {:noreply, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>}} # FIXME terminate, disconnect transport
  end


  @doc false
  def handle_info({:dbux_transport_receive, bitstream}, %{mod: mod, mod_state: mod_state, state: :authenticated, hello_serial: hello_serial, buffer: buffer, unwrap_values: unwrap_values} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: Received when authenticated")

    case DBux.Message.unmarshall(buffer <> bitstream, unwrap_values) do
      {:ok, {message, rest}} ->
        if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: Received message #{inspect(message)}")
        cond do
          message.reply_serial == hello_serial ->
            unique_name = hd(message.body)
            if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Got unique name #{unique_name}")

            case mod.handle_up(mod_state) do
              {:noreply, new_mod_state} ->
                {:noreply, %{state | state: :ready, unique_name: unique_name, buffer: rest, mod_state: new_mod_state}}
            end

          true ->
            Logger.warn("[DBux.Connection #{inspect(self())}] Got unknown reply #{inspect(message)}")
            {:noreply, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>}} # FIXME terminate, disconnect transport
        end

      {:error, :bitstring_too_short} ->
        {:noreply, %{state | buffer: buffer <> bitstream}}

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to parse message: reason = #{inspect(reason)}")
        {:noreply, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>}} # FIXME terminate, disconnect transport
    end
  end


  @doc false
  def handle_info({:dbux_transport_receive, bitstream}, %{mod: mod, mod_state: mod_state, state: :ready, buffer: buffer, unwrap_values: unwrap_values} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: Received when ready")

    case DBux.Message.unmarshall(buffer <> bitstream, unwrap_values) do
      {:ok, {message, rest}} ->
        if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: Received message = #{inspect(message)}")

        callback_return = case message.message_type do
          :method_call ->
            mod.handle_method_call(message.serial, message.path, message.member, message.interface, message.body, mod_state)

          :method_return ->
            mod.handle_method_return(message.serial, message.reply_serial, message.body, mod_state)

          :error ->
            mod.handle_error(message.serial, message.reply_serial, message.error_name, message.body, mod_state)

          :signal ->
            mod.handle_signal(message.serial, message.path, message.member, message.interface, message.body, mod_state)
        end

        case callback_return do
          {:noreply, new_mod_state} ->
            {:noreply, %{state | buffer: rest, mod_state: new_mod_state}}
        end

      {:error, :bitstring_too_short} ->
        {:noreply, %{state | buffer: buffer <> bitstream}}

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to parse message: reason = #{inspect(reason)}")
        {:noreply, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>}} # FIXME terminate, disconnect transport
    end
  end


  @doc false
  def handle_info(info, %{mod: mod, mod_state: mod_state} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: Generic, info = #{inspect(info)}")
    case mod.handle_info(info, mod_state) do
      {:noreply, new_mod_state} ->
        {:noreply, %{state | mod_state: new_mod_state}}

      {:noreply, new_mod_state, timeout} ->
        {:noreply, %{state | mod_state: new_mod_state}, timeout}

      {:connect, info, new_mod_state} ->
        {:connect, info, %{state | mod_state: new_mod_state}}

      {:disconnect, info, new_mod_state} ->
        {:disconnect, info, %{state | mod_state: new_mod_state}}

      {:stop, info, new_mod_state} ->
        {:stop, info, %{state | mod_state: new_mod_state}}
    end
  end


  defp send_message(%DBux.Message{} = message, %{transport_mod: transport_mod, transport_proc: transport_proc, serial_proc: serial_proc}) do
    serial = DBux.Serial.retreive(serial_proc)
    message_with_serial = Map.put(message, :serial, serial)

    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Sending message: #{inspect(message_with_serial)}")
    {:ok, message_bitstring} = message_with_serial |> DBux.Message.marshall

    case transport_mod.do_send(transport_proc, message_bitstring) do
      :ok ->
        {:ok, serial}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
