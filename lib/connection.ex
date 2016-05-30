defmodule DBux.Connection do
  require Logger
  use Connection

  @connect_timeout 5000
  @reconnect_timeout 5000

  @debug !is_nil(System.get_env("DBUX_DEBUG"))

  @doc """
  Called when Connection process is first started. `start_link/5` will block
  until it returns.

  Returning `{:ok, state}` will cause `start_link/5` to return
  `{:ok, pid}` and the process to enter its loop with state `state`
  """
  @callback init(module, map, module, map, String.t) ::
    {:ok, any}

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
      def init(_transport_mod, _transport_opts, _auth_mod, _auth_opts, _name) do
        {:ok, %{}}
      end

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
        init: 5,
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

  `transport_mod` is a module that will be used for transport. So far only
  `DBux.Transport.TCP` is supported.

  `transport_opts` are options that will be passed to transport. Refer to
  individual transports' docs.

  `auth_mod` is a module that will be used for authentication. So far only
  `DBux.Auth.Anonymous` is supported.

  `auth_opts` are options that will be passed to authentication module. Refer to
  individual authenticators' docs.

  It returns the same body as `GenServer.start_link`.
  """
  @spec start_link(module, module, map, module, map) :: GenServer.on_start
  def start_link(mod, transport_mod, transport_opts, auth_mod, auth_opts) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Start link: transport = #{transport_mod}, transport_opts = #{inspect(transport_opts)}, auth = #{auth_mod}, auth_opts = #{inspect(auth_opts)}")

    initial_state = %{
      mod:                 mod,
      mod_state:           nil,
      state:               :init,
      transport_mod:       transport_mod,
      transport_opts:      transport_opts,
      transport_proc:      nil,
      auth_mod:            auth_mod,
      auth_opts:           auth_opts,
      auth_proc:           nil,
      serial_proc:         nil,
      unique_name:         nil,
      hello_serial:        nil,
      buffer:              << >>,
      unwrap_values:       true
    }

    Connection.start_link(__MODULE__, initial_state)
  end


  @doc """
  Causes bus to synchronously send method call to given path, interface,
  destination, poptionally with body.

  It returns `{:ok, serial}` in case of success, `{:error, reason}` otherwise.
  Please note that `{:error, reason}` does not mean error reply over D-Bus, it
  means an internal application error.
  """
  @spec do_method_call(pid, String.t, String.t, String.t, list, String.t | nil) :: {:ok, DBux.Serial.t} | {:error, any}
  def do_method_call(bus, path, interface, member, body \\ [], destination \\ nil) when is_pid(bus) and is_binary(path) and is_binary(interface) and is_binary(member) and is_list(body) and (is_binary(destination) or is_nil(destination)) do
    Connection.call(bus, {:dbux_method_call, path, interface, member, body, destination})
  end


  @spec do_request_name(pid, String.t) :: :ok | {:error, any}
  def do_request_name(bus, name) do
    Connection.call(bus, {:dbux_request_name, name})
  end


  @doc false
  def init(%{mod: mod, transport_mod: transport_mod, transport_opts: transport_opts, auth_mod: auth_mod, auth_opts: auth_opts} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Init")

    {:ok, transport_proc} = transport_mod.start_link(self(), transport_opts)
    {:ok, auth_proc}      = auth_mod.start_link(self(), auth_opts)
    {:ok, serial_proc}    = DBux.Serial.start_link()
    {:ok, mod_state}      = mod.init(transport_mod, transport_opts, auth_mod, auth_opts)

    {:connect, :init,
      %{state |
        transport_proc: transport_proc,
        auth_proc:      auth_proc,
        serial_proc:    serial_proc,
        mod_state:      mod_state}}
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
  def handle_call({:dbux_method_call, path, interface, member, body, destination}, _sender, %{state: :authenticated} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle call: send method call when authenticated")
    case send_method_call(path, interface, member, body, destination, state) do
      {:ok, serial} ->
        {:reply, {:ok, serial}, state}

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to send method call: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  @doc false
  def handle_call({:dbux_request_name, name}, _sender, %{state: :ready} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle call: request name when ready")
    case send_request_name(name, state) do
      {:ok, serial} ->
        {:reply, {:ok, serial}, state}

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to request name: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  @doc false
  def handle_call(_message, _sender, state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle call: send method call when not authenticated")
    {:reply, {:error, :not_authenticated}, state}
  end


  @doc false
  def handle_info(:dbux_authentication_succeeded, %{state: :authenticating, transport_mod: transport_mod, transport_proc: transport_proc} = state) do
    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: authentication succeeded")

    if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Beginning message transmission")
    case transport_mod.do_begin(transport_proc) do
      :ok ->
        if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Began message transmission")

        if @debug, do: Logger.debug("[DBux.Connection #{inspect(self())}] Sending Hello")
        case send_hello(state) do
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


  defp send_method_call(path, interface, member, body, destination \\ nil, state) do
    # Serial will be added later
    send_message(DBux.Message.build_method_call(0, path, interface, member, body, destination), state)
  end


  defp send_hello(state) do
    send_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "Hello", [], "org.freedesktop.DBus", state)
  end


  defp send_request_name(name, state) do
    send_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "RequestName", [%DBux.Value{type: :string, value: name}, %DBux.Value{type: :uint32, value: 0}], "org.freedesktop.DBus", state)
  end
end
