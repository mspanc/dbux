defmodule DBux.Connection do
  require Logger
  use GenServer

  @connect_timeout 5000
  @reconnect_timeout 5000


  # @callback handle_connected(any) ::
  #   {:ok, any}


  defmacro __using__(_) do
    quote location: :keep do
      @behaviour DBux.Connection

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
    {:ok, message_bitstring, _} = %{message | serial: serial} |> DBux.Message.marshall

    case transport_mod.do_send(transport_proc, message_bitstring) do
      :ok ->
        {:ok, serial}

      {:error, reason} ->
        {:error, reason}
    end
  end


  defp send_method_call(path, interface, member, body, destination \\ nil, state) do
    send_message(%DBux.Message{type: :method_call, path: path, interface: interface, member: member, body: body, destination: destination}, state)
  end


  defp send_hello(state) do
    send_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "Hello", [], "org.freedesktop.DBus", state)
  end
end
