defmodule DBux.Connection do
  require Logger
  use GenServer

  @connect_timeout 5000
  @reconnect_timeout 5000


  @doc """
  Called when Connection process is first started. `start_link/5` will block
  until it returns.

  Returning `{:ok, state}` will cause `start_link/5` to return
  `{:ok, pid}` and the process to enter its loop with state `state`
  """
  @callback init(module, map, module, map) ::
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
  @callback handle_method_call(number, String.t, String.t, String.t, [] | [%DBux.Value{}], any) ::
    {:noreply, any}

  @doc """
  Called when we receive a method return.

  Returning `{:noreply, state}` will cause to update state with `state`.
  """
  @callback handle_method_return(number, number, %DBux.Value{}, any) ::
    {:noreply, any}

  @doc """
  Called when we receive an error.

  Returning `{:noreply, state}` will cause to update state with `state`.
  """
  @callback handle_error(number, number, String.t, any) ::
    {:noreply, any}

  @doc """
  Called when we receive a signal.

  Returning `{:noreply, state}` will cause to update state with `state`.
  """
  @callback handle_signal(number, String.t, String.t, String.t, any) ::
    {:noreply, any}


  defmacro __using__(_) do
    quote location: :keep do
      @behaviour DBux.Connection

      # Default implementations

      @doc false
      def init(_transport_mod, _transport_opts, _auth_mod, _auth_opts) do
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
      def handle_method_call(_serial, _path, _member, _interface, _values, state) do
        {:noreply, state}
      end

      @doc false
      def handle_method_return(_serial, _reply_serial, return_value, state) do
        {:noreply, state}
      end

      @doc false
      def handle_error(_serial, _reply_serial, _error_name, state) do
        {:noreply, state}
      end

      @doc false
      def handle_signal(_serial, _path, _member, _interface, state) do
        {:noreply, state}
      end

      defoverridable [
        init: 4,
        handle_up: 1,
        handle_down: 1,
        handle_method_call: 6,
        handle_method_return: 4,
        handle_error: 4,
        handle_signal: 5]
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
    Logger.debug("[DBux.Connection #{inspect(self())}] Start link: transport = #{transport_mod}, transport_opts = #{inspect(transport_opts)}, auth = #{auth_mod}, auth_opts = #{inspect(auth_opts)}")

    initial_state = %{
      mod:            mod,
      state:          :init,
      transport_mod:  transport_mod,
      transport_opts: transport_opts,
      transport_proc: nil,
      auth_mod:       auth_mod,
      auth_opts:      auth_opts,
      auth_proc:      nil,
      serial_proc:    nil
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
  @spec do_method_call(pid, String.t, String.t, String.t, list, String.t | nil) :: :ok | {:error, any}
  def do_method_call(bus, path, interface, member, body \\ [], destination \\ nil) when is_pid(bus) and is_binary(path) and is_binary(interface) and is_binary(member) and is_list(body) and (is_binary(destination) or is_nil(destination)) do
    Connection.call(bus, {:send_method_call, path, interface, member, body, destination})
  end


  @doc false
  def init(%{transport_mod: transport_mod, transport_opts: transport_opts, auth_mod: auth_mod, auth_opts: auth_opts} = state) do
    Logger.debug("[DBux.Connection #{inspect(self())}] Init")

    {:ok, transport_proc} = transport_mod.start_link(self(), transport_opts)
    {:ok, auth_proc}      = auth_mod.start_link(self(), auth_opts)
    {:ok, serial_proc}    = DBux.Serial.start_link()

    {:connect, :init,
      %{state |
        transport_proc: transport_proc,
        auth_proc:      auth_proc,
        serial_proc:    serial_proc}}
  end


  @doc false
  def connect(_, %{transport_mod: transport_mod, transport_proc: transport_proc, auth_mod: auth_mod, auth_proc: auth_proc} = state) do
    Logger.debug("[DBux.Connection #{inspect(self())}] Connecting")
    case transport_mod.do_connect(transport_proc) do
      :ok ->
        Logger.debug("[DBux.Connection #{inspect(self())}] Authenticating")
        case auth_mod.do_handshake(auth_proc, transport_mod, transport_proc) do
          :ok ->
            Logger.debug("[DBux.Connection #{inspect(self())}] Sent authentication request")
            {:ok, %{state | state: :authenticating}}

          {:error, _} ->
            Logger.warn("[DBux.Connection #{inspect(self())}] Failed to send authentication request")
            {:backoff, @reconnect_timeout, %{state | state: :init}}
        end

      {:error, _} ->
        Logger.debug("[DBux.Connection #{inspect(self())}] Failed to connect")
        {:backoff, @reconnect_timeout, %{state | state: :init}}
    end
  end


  @doc false
  def handle_call({:send_method_call, path, interface, member, body, destination}, _sender, %{state: :authenticated} = state) do
    Logger.debug("[DBux.Connection #{inspect(self())}] Handle call: send method call when authenticated")
    case send_method_call(path, interface, member, body, destination, state) do
      {:ok, serial} ->
        {:reply, {:ok, serial}, state}

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to send method call: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  @doc false
  def handle_call(_message, _sender, state) do
    Logger.debug("[DBux.Connection #{inspect(self())}] Handle call: send method call when not authenticated")
    {:reply, {:error, :not_authenticated}, state}
  end


  @doc false
  def handle_info(:authentication_succeeded, %{state: :authenticating, transport_mod: transport_mod, transport_proc: transport_proc} = state) do
    Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: authentication succeeded")

    Logger.debug("[DBux.Connection #{inspect(self())}] Beginning message transmission")
    case transport_mod.do_begin(transport_proc) do
      :ok ->
        Logger.debug("[DBux.Connection #{inspect(self())}] Began message transmission")

        Logger.debug("[DBux.Connection #{inspect(self())}] Sending Hello")
        case send_hello(state) do
          {:ok, _} ->
            {:noreply, %{state | state: :authenticated}}

          {:error, reason} ->
            Logger.warn("[DBux.Connection #{inspect(self())}] Failed to send Hello: #{inspect(reason)}")
            {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
        end

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to begin message transmission: #{inspect(reason)}")
        {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
    end
  end


  @doc false
  def handle_info(:authentication_failed, %{state: :authenticating} = state) do
    Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: authentication failed")
    {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
  end


  @doc false
  def handle_info(:authentication_error, %{state: :authenticating} = state) do
    Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: authentication error")
    {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
  end


  @doc false
  def handle_info(:transport_down, state) do
    Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: Transport down")
    {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
  end


  @doc false
  def handle_info({:receive, data}, %{state: :authenticated} = state) do
    Logger.debug("[DBux.Connection #{inspect(self())}] Handle info: Received")

    # TODO handle case in which amount of data is smaller than header
    DBux.Message.unmarshall(data)

    {:noreply, state}
  end


  defp send_message(%DBux.Message{} = message, %{transport_mod: transport_mod, transport_proc: transport_proc, serial_proc: serial_proc}) do
    serial = DBux.Serial.retreive(serial_proc)
    {:ok, message_bitstring} = %{message | serial: serial} |> DBux.Message.marshall

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
end
