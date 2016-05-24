defmodule DBux.Bus do
  require Logger
  use GenServer

  @connect_timeout 5000
  @reconnect_timeout 5000


  @callback handle_connected(any) ::
    {:ok, any}


  defmacro __using__(_) do
    quote location: :keep do
      @behaviour DBux.Bus

    end
  end


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


  def handle_call({:message, message}, _sender, %{transport_mod: transport_mod, transport_proc: transport_proc, state: :authenticated} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle call: message")
    {:ok, message_bitstring, _} = message |> DBux.Message.marshall(:little_endian)
    case transport_mod.do_send(transport_proc, message_bitstring) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.warn("[DBux.Bus #{inspect(self())}] Failed to send message: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  def handle_info(:authentication_succeeded, %{state: :authenticating, transport_mod: transport_mod, transport_proc: transport_proc} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle info: authentication succeeded")
    case transport_mod.do_send(transport_proc, "BEGIN\r\n") do
      :ok ->
        Logger.debug("[DBux.Bus #{inspect(self())}] Sent BEGIN")
        {:noreply, %{state | state: :authenticated}}

      {:error, reason} ->
        Logger.warn("[DBux.Bus #{inspect(self())}] Failed to send BEGIN: #{inspect(reason)}")
        {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
    end
  end


  def handle_info(:authentication_failed, %{state: :authenticating} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle info: authentication failed")
    {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
  end


  def handle_info(:authentication_error, %{state: :authenticating} = state) do
    Logger.debug("[DBux.Bus #{inspect(self())}] Handle info: authentication error")
    {:noreply, %{state | state: :init}} # FIXME terminate, disconnect transport
  end


  def do_method_call(bus, path, interface, member, values \\ [], destination \\ nil) do
    # FIXME get serial from agent
    Connection.call(bus, {:message, %DBux.Message{serial: 1, type: :method_call, path: path, interface: interface, member: member, values: values, destination: destination}})
  end


  # TODO handle message when not authenticated
end
