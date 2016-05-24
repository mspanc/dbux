defmodule DBux.Bus do
  require Logger
  use GenServer

  @connect_timeout 5000
  @reconnect_timeout 5000


  # @callback handle_connected(any) ::
  #   {:ok, any}


  defmacro __using__(_) do
    quote location: :keep do
      @behaviour DBux.Bus

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

  It returns the same values as `GenServer.start_link`.
  """
  @spec start_link(module, module, map, module, map) :: GenServer.on_start
  def start_link(mod, transport_mod, transport_opts, auth_mod, auth_opts) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Start link: transport = #{transport_mod}, transport_opts = #{inspect(transport_opts)}, auth = #{auth_mod}, auth_opts = #{inspect(auth_opts)}")

    initial_state = %{
      mod:            mod,
      state:          :init,
      transport_mod:  transport_mod,
      transport_opts: transport_opts,
      transport_proc: nil,
      auth_mod:       auth_mod,
      auth_opts:      auth_opts,
      auth_proc:      nil
    }

    Connection.start_link(__MODULE__, initial_state)
  end


  @doc """
  Causes bus to synchronously send method call to given path, interface,
  destination, with values passed as message parameters.

  It returns `:ok` in case of success, `{:error, reason}` otherwise.
  """
  @spec do_method_call(pid, String.t, String.t, String.t, list, String.t) :: :ok | {:error, any}
  def do_method_call(bus, path, interface, member, values \\ [], destination) when is_pid(bus) and is_binary(path) and is_binary(interface) and is_binary(member) and is_list(values) and is_binary(destination) do
    Connection.call(bus, {:send_method_call, path, interface, member, values, destination})
  end


  @doc false
  def init(%{transport_mod: transport_mod, transport_opts: transport_opts, auth_mod: auth_mod, auth_opts: auth_opts} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Init")

    {:ok, transport_proc} = transport_mod.start_link(self(), transport_opts)
    {:ok, auth_proc} = auth_mod.start_link(self(), auth_opts)

    {:connect, :init,
      %{state |
        transport_proc: transport_proc,
        auth_proc:      auth_proc}}
  end


  @doc false
  def connect(_, %{transport_mod: transport_mod, transport_proc: transport_proc, auth_mod: auth_mod, auth_proc: auth_proc} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Connecting")
    case transport_mod.do_connect(transport_proc) do
      :ok ->
        Logger.debug("[DBux.Bus #{inspect(self())}] Authenticating")
        case auth_mod.do_handshake(auth_proc, transport_mod, transport_proc) do
          :ok ->
            Logger.debug("[DBux.Bus #{inspect(self())}] Sent authentication request")
            {:ok, %{state | state: :authenticating}}

          {:error, _} ->
            Logger.warn("[DBux.Bus #{inspect(self())}] Failed to send authentication request")
            {:backoff, @reconnect_timeout, %{state | state: :init}}
        end

      {:error, _} ->
        Logger.debug("[DBux.Bus #{inspect(self())}] Failed to connect")
        {:backoff, @reconnect_timeout, %{state | state: :init}}
    end
  end


  @doc false
  def handle_call({:send_method_call, path, interface, member, values, destination}, _sender, %{state: :authenticated} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle call: send method call when authenticated")
    case send_method_call(path, interface, member, values, destination, state) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.warn("[DBux.Bus #{inspect(self())}] Failed to send method call: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  @doc false
  def handle_call(_message, _sender, state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle call: send method call when not authenticated")
    {:reply, {:error, :not_authenticated}, state}
  end


  @doc false
  def handle_info(:authentication_succeeded, %{state: :authenticating, transport_mod: transport_mod, transport_proc: transport_proc} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle info: authentication succeeded")

    Logger.debug("[DBux.Bus #{inspect(self())}] Beginning message transmission")
    case transport_mod.do_send(transport_proc, "BEGIN\r\n") do
      :ok ->
        Logger.debug("[DBux.Bus #{inspect(self())}] Began message transmission")

        Logger.debug("[DBux.Bus #{inspect(self())}] Sending Hello")
        case send_hello(state) do
          :ok ->
            {:noreply, %{state | state: :authenticated}}

          {:error, reason} ->
            Logger.warn("[DBux.Bus #{inspect(self())}] Failed to send Hello: #{inspect(reason)}")
            {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
        end

      {:error, reason} ->
        Logger.warn("[DBux.Bus #{inspect(self())}] Failed to begin message transmission: #{inspect(reason)}")
        {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
    end
  end


  @doc false
  def handle_info(:authentication_failed, %{state: :authenticating} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle info: authentication failed")
    {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
  end


  @doc false
  def handle_info(:authentication_error, %{state: :authenticating} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle info: authentication error")
    {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
  end


  @doc false
  def handle_info(:transport_down, state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle info: Transport down")
    {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
  end



  defp send_method_call(path, interface, member, values, destination, %{transport_mod: transport_mod, transport_proc: transport_proc} = state) do
    # FIXME get serial from agent
    message = %DBux.Message{serial: 1, type: :method_call, path: path, interface: interface, member: member, values: values, destination: destination}
    {:ok, message_bitstring, _} = message |> DBux.Message.marshall
    transport_mod.do_send(transport_proc, message_bitstring)
  end


  defp send_hello(state) do
    send_method_call("/org/freedesktop/DBus", "org.freedesktop.DBus", "Hello", [], "org.freedesktop.DBus", state)
  end
end
