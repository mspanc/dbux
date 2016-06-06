defmodule DBux.PeerConnection do
  @moduledoc """
  This module handles connection to the another D-Bus peer.

  At the moment it handles only connections to the buses.

  It basically allows to establish a connection and then send and receive messages.
  Its interface is intentionally quite low-level. You probably won't be able to
  use it properly without understanding how D-Bus protocol works.

  An example `DBux.PeerConnection` process:

      defmodule MyApp.Bus do
        require Logger
        use DBux.PeerConnection

        @request_name_message_id :request_name
        @add_match_message_id    :add_match

        @introspection \"\"\"
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
        \"\"\"

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
  """

  require Logger
  use Connection

  @connect_timeout 5000
  @reconnect_timeout 5000

  @type message_queue_id :: String.t | atom | number
  @type message_queue :: [] | [%DBux.Message{} | {message_queue_id, %DBux.Message{}}]

  @debug !is_nil(System.get_env("DBUX_DEBUG"))


  @doc """
  Called when PeerConnection process is first started. `start_link/1` will block
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

  Returning `{:send, list_of_messages, state}` will cause to update state with
  `state` and send messages passed as the second element of the tuple. The list
  can just contain `DBux.Message` structs or `{identifier, %DBux.Message{}}`
  tuples, where `identifier` is an arbitrary identifier that will allow later
  to match response with the message.
  """
  @callback handle_up(any) ::
    {:noreply, any} |
    {:send, message_queue}


  @doc """
  Called when connection is lost.

  Returning `{:connect, state}` will cause to try to reconnect immediately.

  Returning `{:backoff, timeout, state}` will cause to try to reconnect after
  `timeout` milliseconds.

  Returning `{:noconnect, state}` will cause to update state with `state`
  and do nothing.

  Returning `{:stop, info, state}` will cause to terminate the process.
  """
  @callback handle_down(any) ::
    {:connect, any} |
    {:backoff, timeout, any} |
    {:noconnect, any} |
    {:stop, any, any}


  @doc """
  Called when we receive a method call.

  Returning `{:noreply, state}` will cause to update state with `state`.

  Returning `{:send, list_of_messages, state}` will cause to update state with
  `state` and send messages passed as the second element of the tuple. The list
  can just contain `DBux.Message` structs or `{identifier, %DBux.Message{}}`
  tuples, where `identifier` is an arbitrary identifier that will allow later
  to match response with the message.
  """
  @callback handle_method_call(DBux.Serial.t, String.t, String.t, String.t, String.t, DBux.Value.list_of_values, number, any) ::
    {:noreply, any} |
    {:send, message_queue}


  @doc """
  Called when we receive a method return.

  Returning `{:noreply, state}` will cause to update state with `state`.

  Returning `{:send, list_of_messages, state}` will cause to update state with
  `state` and send messages passed as the second element of the tuple. The list
  can just contain `DBux.Message` structs or `{identifier, %DBux.Message{}}`
  tuples, where `identifier` is an arbitrary identifier that will allow later
  to match response with the message.
  """
  @callback handle_method_return(DBux.Serial.t, String.t, DBux.Serial.t, DBux.Value.list_of_values, message_queue_id, any) ::
    {:noreply, any} |
    {:send, message_queue}


  @doc """
  Called when we receive an error.

  Returning `{:noreply, state}` will cause to update state with `state`.

  Returning `{:send, list_of_messages, state}` will cause to update state with
  `state` and send messages passed as the second element of the tuple. The list
  can just contain `DBux.Message` structs or `{identifier, %DBux.Message{}}`
  tuples, where `identifier` is an arbitrary identifier that will allow later
  to match response with the message.
  """
  @callback handle_error(DBux.Serial.t, String.t, DBux.Serial.t, String.t, DBux.Value.list_of_values, message_queue_id, any) ::
    {:noreply, any} |
    {:send, message_queue}


  @doc """
  Called when we receive a signal.

  Returning `{:noreply, state}` will cause to update state with `state`.

  Returning `{:send, list_of_messages, state}` will cause to update state with
  `state` and send messages passed as the second element of the tuple. The list
  can just contain `DBux.Message` structs or `{identifier, %DBux.Message{}}`
  tuples, where `identifier` is an arbitrary identifier that will allow later
  to match response with the message.
  """
  @callback handle_signal(DBux.Serial.t, String.t, String.t, String.t, String.t, DBux.Value.list_of_values, any) ::
    {:noreply, any} |
    {:send, message_queue}


  @doc """
  Called when we receive a call.

  Returning `{:noreply, state}` will cause to update state with `state`.

  Returning `{:reply, value, state}` will cause to update state with `state` and
  return `value` to the caller .

  Returning `{:stop, reason, state}` will cause to terminate the process.

  Returning `{:send, list_of_messages, state}` will cause to update state with
  `state` and send messages passed as the second element of the tuple. The list
  can just contain `DBux.Message` structs or `{identifier, %DBux.Message{}}`
  tuples, where `identifier` is an arbitrary identifier that will allow later
  to match response with the message.
  """
  @callback handle_call(any, GenServer.server, any) ::
    {:reply, any, any} |
    {:noreply, any} |
    {:stop, any, any} |
    {:send, message_queue}



  defmacro __using__(_) do
    quote location: :keep do
      @behaviour DBux.PeerConnection

      # Default implementations

      @doc false
      def handle_up(state) do
        {:noreply, state}
      end


      @doc false
      def handle_down(state) do
        {:backoff, 1000, state}
      end


      @doc false
      def handle_method_call(_serial, _sender, _path, _member, _interface, _body, _flags, state) do
        {:noreply, state}
      end


      @doc false
      def handle_method_return(_serial, _sender, _reply_serial, _body, _queue_id, state) do
        {:noreply, state}
      end


      @doc false
      def handle_error(_serial, _sender, _reply_serial, _error_name, _body, _queue_id, state) do
        {:noreply, state}
      end


      @doc false
      def handle_signal(_serial, _sender, _path, _member, _interface, _body, state) do
        {:noreply, state}
      end


      @doc false
      def handle_call(msg, _from, state) do
        # We do this to trick dialyzer to not complain about non-local returns.
        reason = {:bad_call, msg}
        case :erlang.phash2(1, 1) do
          0 -> exit(reason)
          1 -> {:stop, reason, state}
        end
      end


      @doc false
      def handle_info(_msg, state) do
        {:noreply, state}
      end


      @doc false
      def handle_cast(msg, state) do
        # We do this to trick dialyzer to not complain about non-local returns.
        reason = {:bad_cast, msg}
        case :erlang.phash2(1, 1) do
          0 -> exit(reason)
          1 -> {:stop, reason, state}
        end
      end


      @doc false
      def terminate(_reason, _state) do
        :ok
      end


      @doc false
      def code_change(_old, state, _extra) do
        {:ok, state}
      end


      defoverridable [
        handle_up: 1,
        handle_down: 1,
        handle_method_call: 8,
        handle_method_return: 6,
        handle_error: 7,
        handle_signal: 7,
        handle_call: 3,
        handle_info: 2,
        handle_cast: 2,
        terminate: 2,
        code_change: 3]
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
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Start link: mod_options = #{inspect(mod_options)}, proc_options = #{inspect(proc_options)}")

    Connection.start_link(__MODULE__, {mod, mod_options}, proc_options)
  end


  @doc """
  Sends DBux.Message.

  Returns `{:ok, serial}` on success.

  Returns `{:error, reason}` otherwise. Please note that error does not mean
  error reply over D-Bus, but internal application error.

  It is a synchronous call.
  """
  @spec send_message(GenServer.server, %DBux.Message{}) :: {:ok, DBux.Serial.t} | {:error, any}
  def send_message(bus, message) when is_map(message) do
    DBux.PeerConnection.call(bus, {:dbux_send_message, message})
  end


  @doc """
  Sends DBux.Message with attributes appropriate for method call.

  Returns `{:ok, serial}` on success.

  Returns `{:error, reason}` otherwise. Please note that error does not mean
  error reply over D-Bus, but internal application error.

  It is a synchronous call.
  """
  @spec send_method_call(GenServer.server, String.t, String.t, DBux.Value.list_of_values, String.t | nil) :: {:ok, DBux.Serial.t} | {:error, any}
  def send_method_call(bus, path, interface, member, body \\ [], destination \\ nil) when is_binary(path) and is_binary(interface) and is_list(body) and (is_binary(destination) or is_nil(destination)) do
    DBux.PeerConnection.call(bus, {:dbux_send_message, DBux.Message.build_method_call(path, interface, member, body, destination)})
  end


  @doc """
  Sends DBux.Message with attributes appropriate for signal.

  Returns `{:ok, serial}` on success.

  Returns `{:error, reason}` otherwise. Please note that error does not mean
  error reply over D-Bus, but internal application error.

  It is a synchronous call.
  """
  @spec send_signal(GenServer.server, String.t, String.t, String.t, DBux.Value.list_of_values) :: {:ok, DBux.Serial.t} | {:error, any}
  def send_signal(bus, path, interface, member, body \\ []) when is_binary(path) and is_binary(interface) and is_list(body) do
    DBux.PeerConnection.call(bus, {:dbux_send_message, DBux.Message.build_signal(path, interface, member, body)})
  end


  @doc """
  Sends DBux.Message with attributes appropriate for method return.

  Returns `{:ok, serial}` on success.

  Returns `{:error, reason}` otherwise. Please note that error does not mean
  error reply over D-Bus, but internal application error.

  It is a synchronous call.
  """
  @spec send_method_return(GenServer.server, DBux.Serial.t, DBux.Value.list_of_values) :: {:ok, DBux.Serial.t} | {:error, any}
  def send_method_return(bus, reply_serial, body \\ []) when is_number(reply_serial) and is_list(body) do
    DBux.PeerConnection.call(bus, {:dbux_send_message, DBux.Message.build_method_return(reply_serial, body)})
  end


  @doc """
  Sends DBux.Message with attributes appropriate for error.

  Returns `{:ok, serial}` on success.

  Returns `{:error, reason}` otherwise. Please note that error does not mean
  error reply over D-Bus, but internal application error.

  It is a synchronous call.
  """
  @spec send_error(GenServer.server, DBux.Serial.t, String.t, DBux.Value.list_of_values) :: {:ok, DBux.Serial.t} | {:error, any}
  def send_error(bus, reply_serial, error_name, body \\ []) when is_number(reply_serial) and is_binary(error_name) and is_list(body) do
    DBux.PeerConnection.call(bus, {:dbux_send_message, DBux.Message.build_error(reply_serial, error_name, body)})
  end


  @doc """
  Sends a synchronous call to the `PeerConnection` process and waits for a reply.
  See `Connection.call/2` for more information.
  """
  defdelegate call(conn, req), to: Connection

  @doc """
  Sends a synchronous request to the `PeerConnection` process and waits for a reply.
  See `Connection.call/3` for more information.
  """
  defdelegate call(conn, req, timeout), to: Connection

  @doc """
  Sends a asynchronous request to the `PeerConnection` process.
  See `Connection.cast/2` for more information.
  """
  defdelegate cast(conn, req), to: Connection

  @doc """
  Sends a reply to a request sent by `call/3`.
  See `Connection.reply/2` for more information.
  """
  defdelegate reply(from, response), to: Connection


  @doc false
  def init({mod, mod_options}) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Init, mod = #{inspect(mod)}, mod_options = #{inspect(mod_options)}")

    {:ok, address, auth_mechanisms, mod_state} = mod.init(mod_options)
    {:ok, {transport_mod, transport_opts}} = DBux.Transport.get_module_for_address(address)
    {:ok, {auth_mod, auth_opts}} = DBux.Auth.get_module_for_method(hd(auth_mechanisms)) # TODO support more mechanisms

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
      unwrap_values:       true,
      message_queue:       %{}
    }

    {:connect, :init, initial_state}
  end


  @doc false
  def connect(_, %{transport_mod: transport_mod, transport_proc: transport_proc, auth_mod: auth_mod, auth_proc: auth_proc} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Connecting")
    case transport_mod.do_connect(transport_proc) do
      :ok ->
        if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Authenticating")
        case auth_mod.do_handshake(auth_proc, transport_mod, transport_proc) do
          :ok ->
            if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Sent authentication request")
            {:ok, %{state | state: :authenticating}}

          {:error, _} ->
            Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to send authentication request")
            {:backoff, @reconnect_timeout, %{state | state: :init}}
        end

      {:error, _} ->
        if @debug, do: Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to connect transport")
        {:backoff, @reconnect_timeout, %{state | state: :init}}
    end
  end


  @doc false
  def disconnect(:error, %{mod: mod, mod_state: mod_state, transport_mod: transport_mod, transport_proc: transport_proc} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Disconnected")

    case transport_mod.do_disconnect(transport_proc) do
      :ok ->
        case mod.handle_down(mod_state) do
          {:connect, new_mod_state} ->
            {:connect, :callback, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>, mod_state: new_mod_state}}

          {:backoff, timeout, new_mod_state} ->
            {:backoff, timeout, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>, mod_state: new_mod_state}}

          {:noconnect, new_mod_state} ->
            {:noconnect, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>, mod_state: new_mod_state}}

          {:stop, info, new_mod_state} ->
            {:stop, info, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>, mod_state: new_mod_state}}
        end

      {:error, _} ->
        if @debug, do: Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to disconnect transport")
        {:backoff, 1000, %{state | state: :init, unique_name: nil, hello_serial: nil, buffer: << >>}}
    end
  end


  @doc false
  def handle_call({:dbux_send_message, _message}, _sender, %{state: :init} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Handle call: send method call when not authenticated")
    {:reply, {:error, :not_authenticated}, state}
  end


  @doc false
  def handle_call({:dbux_send_message, message}, _sender, state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Handle call: send message when authenticated: message = #{inspect(message)}")
    case do_send_message(message, state) do
      {:ok, serial} ->
        {:reply, {:ok, serial}, state}

      {:error, reason} ->
        Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to send method call: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  @doc false
  def handle_call(msg, sender, %{mod: mod, mod_state: mod_state} = state) do
    case mod.handle_call(msg, sender, mod_state) do
      {:reply, reply_value, new_mod_state} ->
        {:reply, reply_value, %{state | mod_state: new_mod_state}}

      {:stop, reason, new_mod_state} ->
        {:stop, reason, %{state | mod_state: new_mod_state}}

      {:noreply, new_mod_state} ->
        {:noreply, %{state | mod_state: new_mod_state}}

      {:send, messages, new_mod_state} ->
        new_state = %{state | mod_state: new_mod_state}
        case do_send_message_queue(messages, new_state) do
          {:ok, new_state} ->
            {:reply, :ok, new_state}

          {:error, reason} ->
            Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to send message queue: reason = #{inspect(reason)}")
            {:reply, {:error, reason}, state}
        end
    end
  end


  @doc false
  def handle_info(:dbux_authentication_succeeded, %{state: :authenticating, transport_mod: transport_mod, transport_proc: transport_proc} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Handle info: authentication succeeded")

    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Beginning message transmission")
    case transport_mod.do_begin(transport_proc) do
      :ok ->
        if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Began message transmission")

        if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Sending Hello")
        case do_send_message(DBux.MessageTemplate.hello(), state) do
          {:ok, serial} ->
            {:noreply, %{state | state: :authenticated, hello_serial: serial}}

          {:error, reason} ->
            Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to send Hello: #{inspect(reason)}")
            {:disconnect, :error, state}
        end

      {:error, reason} ->
        Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to begin message transmission: #{inspect(reason)}")
        {:disconnect, :error, state}
    end
  end


  @doc false
  def handle_info(:dbux_authentication_failed, %{state: :authenticating} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Handle info: authentication failed")
    {:disconnect, :error, state}
  end


  @doc false
  def handle_info(:dbux_authentication_error, %{state: :authenticating} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Handle info: authentication error")
    {:disconnect, :error, state}
  end


  @doc false
  def handle_info(:dbux_transport_down, state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Handle info: transport down")
    {:disconnect, :error, state}
  end


  @doc false
  def handle_info({:dbux_transport_receive, bitstring}, %{buffer: buffer} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Handle info: transport receive")

    case parse_received_data(buffer <> bitstring, state) do
      {:ok, new_state} ->
        {:noreply, new_state}

      {:error, reason} ->
        Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to parse received data: reason = #{inspect(reason)}")
        {:disconnect, :error, state}
    end
  end


  @doc false
  def handle_info(info, %{mod: mod, mod_state: mod_state} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Handle info: Generic, info = #{inspect(info)}")
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


  defp parse_received_data(bitstring, %{mod: mod, mod_state: mod_state, unwrap_values: unwrap_values, message_queue: message_queue, hello_serial: hello_serial} = state) do
    case DBux.Message.unmarshall(bitstring, unwrap_values) do
      {:ok, {message, rest}} ->
        if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Parsed received message, message = #{inspect(message)}")

        return = case message.message_type do
          :method_call ->
            {:ok, {mod.handle_method_call(message.serial, message.sender, message.path, message.member, message.interface, message.body, message.flags, mod_state), message_queue}, state}

          :method_return ->
            cond do
              message.reply_serial == hello_serial ->
                case message.message_type do
                  :method_return ->
                    {:ok, {mod.handle_up(mod_state), message_queue}, %{state | hello_serial: nil}}

                  _ ->
                    {:error, :hellofailed}
                end

              true ->
                case message_queue |> Map.pop(message.reply_serial) do
                  {{id, _}, new_message_queue} ->
                    {:ok, {mod.handle_method_return(message.serial, message.sender, message.reply_serial, message.body, id, mod_state), new_message_queue}, state}

                  {nil, new_message_queue} ->
                    {:ok, {mod.handle_method_return(message.serial, message.sender, message.reply_serial, message.body, nil, mod_state), new_message_queue}, state}
                end
            end

          :error ->
            case message_queue |> Map.pop(message.reply_serial) do
              {{id, _}, new_message_queue} ->
                {:ok, {mod.handle_error(message.serial, message.sender, message.reply_serial, message.error_name, message.body, id, mod_state), new_message_queue}, state}

              {nil, new_message_queue} ->
                {:ok, {mod.handle_error(message.serial, message.sender, message.reply_serial, message.error_name, message.body, nil, mod_state), new_message_queue}, state}
            end

          :signal ->
            {:ok, {mod.handle_signal(message.serial, message.sender, message.path, message.member, message.interface, message.body, mod_state), message_queue}, state}
        end


        case return do
          {:ok, {callback_return, new_message_queue}, new_state} ->
            case callback_return do
              {:noreply, new_mod_state} ->
                parse_received_data(rest, %{new_state | buffer: rest, mod_state: new_mod_state, message_queue: new_message_queue})

              {:send, messages, new_mod_state} ->
                new_state = %{new_state | buffer: rest, mod_state: new_mod_state, message_queue: new_message_queue}

                case do_send_message_queue(messages, new_state) do
                  {:ok, new_state} ->
                    parse_received_data(rest, new_state)

                  {:error, reason} ->
                    Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to send message queue: reason = #{inspect(reason)}")
                    {:disconnect, :error, new_state}
                end
            end

          {:error, reason} ->
            Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to parse received data: #{inspect(reason)}")
            {:disconnect, :error, state}
        end

      {:error, :bitstring_too_short} ->
        if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Finished parsing received messages, bitstring too short")
        {:ok, %{state | buffer: bitstring}}

      {:error, reason} ->
        Logger.warn("[DBux.PeerConnection #{inspect(self())}] Failed to parse message: reason = #{inspect(reason)}")
        {:error, reason}
    end
  end


  defp do_send_message_queue([], state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Sending message queue: finish, state = #{inspect(state)}")
    {:ok, state}
  end


  defp do_send_message_queue([{id, message}|rest], %{message_queue: message_queue} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Sending message queue: id = #{inspect(id)}, message = #{inspect(message)}, rest = #{inspect(rest)}, state = #{inspect(state)}")
    case do_send_message(message, state) do
      {:ok, serial} ->
        case message.message_type do
          :method_call ->
            do_send_message_queue(rest, %{state | message_queue: message_queue |> Map.put(serial, {id, System.system_time})})

          _ ->
            do_send_message_queue(rest, state)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end


  defp do_send_message_queue([message|rest], %{message_queue: message_queue} = state) do
    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Sending message queue: message = #{inspect(message)}, rest = #{inspect(rest)}, state = #{inspect(state)}")
    case do_send_message(message, state) do
      {:ok, serial} ->
        case message.message_type do
          :method_call ->
            do_send_message_queue(rest, state)

          _ ->
            do_send_message_queue(rest, %{state | message_queue: message_queue |> Map.put(serial, {nil, System.system_time})})
        end

      {:error, reason} ->
        {:error, reason}
    end
  end


  defp do_send_message(message, %{transport_mod: transport_mod, transport_proc: transport_proc, serial_proc: serial_proc}) do
    serial = DBux.Serial.retreive(serial_proc)
    message_with_serial = Map.put(message, :serial, serial)

    if @debug, do: Logger.debug("[DBux.PeerConnection #{inspect(self())}] Sending message: #{inspect(message_with_serial)}")
    {:ok, message_bitstring} = message_with_serial |> DBux.Message.marshall

    case transport_mod.do_send(transport_proc, message_bitstring) do
      :ok ->
        {:ok, serial}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
