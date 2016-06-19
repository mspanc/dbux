defmodule DBux.Transport.TCP do
  require Logger
  use Connection

  # FIXME do refactor, that still contains some logic, but should contain only
  # transport-related code

  @behaviour DBux.Transport

  # Connect timeout should be lower than 5000, which is default value for
  # GenServer.call. If it is going to be equal or higher, and there will be
  # a connection timeout, the calling process will crash due to timeout in call.
  # If you have ever needed to increase this timeout, remember about adding
  # substantially larger timeout to calls.
  @connect_timeout   3000
  @reconnect_timeout 1000

  @debug !is_nil(System.get_env("DBUX_DEBUG"))

  def start_link(parent, options) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Start link")
    Connection.start_link(__MODULE__, {parent, options})
  end


  def do_connect(transport_proc) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Do connect: #{inspect(transport_proc)}")
    Connection.call(transport_proc, :connect)
  end


  def do_disconnect(transport_proc) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Do disconnect: #{inspect(transport_proc)}")
    Connection.call(transport_proc, :disconnect)
  end


  def do_send(transport_proc, data) when is_binary(data) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Do send: #{inspect(transport_proc)}")
    Connection.call(transport_proc, {:send, data})
  end


  def do_begin(transport_proc) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Do begin: #{inspect(transport_proc)}")
    Connection.call(transport_proc, :begin)
  end


  @doc false
  def init({parent, options}) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Init")
    {:ok, %{ parent: parent, sock: nil, state: :handshake, host: options[:host], port: options[:port]}}
  end


  @doc false
  def connect(_, %{host: host, port: port} = state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Connect: Connecting to #{host}:#{port}")
    case :gen_tcp.connect(to_char_list(host), port, [active: true, mode: :binary, packet: :line, keepalive: true, nodelay: true], @connect_timeout) do
      {:ok, sock} ->
        if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Connect: Successfully connected to #{host}:#{port}")
        {:ok, %{state | sock: sock, state: :handshake}}

      {:error, reason} ->
        Logger.warn("[DBux.Transport.TCP #{inspect(self())}] Connect: Failed to connect to #{host}:#{port}: #{inspect(reason)}")
        {:backoff, @reconnect_timeout, %{state | sock: nil, state: :handshake}}
    end
  end

  @doc false
  def disconnect(_, %{sock: sock} = state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Disconnect")
    :ok = :gen_tcp.close(sock)
    {:noconnect, %{state | sock: nil, state: :handshake}}
  end


  # Handles :connect calls when we are not connected.
  #
  # It instructs to connect and replies `:ok` to the sender.
  @doc false
  def handle_call(:connect, _sender, %{sock: nil} = state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Connect while disconnected")
    {:connect, :call, :ok, state}
  end


  # Handles :connect calls when we are already connected.
  #
  # It replies `{:error, :already_connected}` to the sender.
  @doc false
  def handle_call(:connect, _sender, state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Connect while connected")
    {:reply, {:error, :already_connected}, state}
  end


  # Handles :disconnect calls when we are not connected.
  #
  # It replies `{:error, :not_connected}` to the sender.
  @doc false
  def handle_call(:disconnect, _sender, %{sock: nil} = state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Disconnect while disconnected")
    {:reply, {:error, :already_connected}, state}
  end


  # Handles :disconnect calls when we are already connected.
  #
  # It instructs to connect and replies `:ok` to the sender.
  @doc false
  def handle_call(:disconnect, _sender, state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Disconnect while connected")
    {:disconnect, :call, :ok, state}
  end


  # Handles :send calls when we are not connected.
  #
  # It replies `{:error, :not_connected}` to the sender.
  @doc false
  def handle_call({:send, _}, _sender, %{sock: nil} = state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Send while disconnected")
    {:reply, {:error, :not_connected}, state}
  end


  # Handles :send calls when we are already connected.
  #
  # It replies `:ok` to the sender in case of success,
  # `{:error, reason}` otherwise.
  @doc false
  def handle_call({:send, data}, _sender, %{sock: sock} = state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Send while connected")
    case :gen_tcp.send(sock, data) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.warn("[DBux.Transport.TCP #{inspect(self())}] Failed to send data: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  # Handles :begin calls when we are not connected.
  #
  # It replies `{:error, :not_connected}` to the sender.
  @doc false
  def handle_call(:begin, _sender, %{sock: nil} = state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Begin while disconnected")
    {:reply, {:error, :not_connected}, state}
  end


  # Handles :begin calls when we are already connected.
  #
  # It replies `:ok` to the sender in case of success,
  # `{:error, reason}` otherwise.
  @doc false
  def handle_call(:begin, _sender, %{sock: sock} = state) do
    if @debug, do: Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Begin while connected")
    case :gen_tcp.send(sock, "BEGIN\r\n") do
      :ok ->
        :inet.setopts(sock, [packet: :raw, active: true])
        {:reply, :ok, %{state | state: :ready}}

      {:error, reason} ->
        Logger.warn("[DBux.Transport.TCP #{inspect(self())}] Failed to begin: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  # Handles asynchronous callback called when underlying TCP connection was closed.
  #
  # It returns `{:disconnect, {:error, :tcp_closed}, state}`.
  @doc false
  def handle_info({:tcp_closed, _}, %{parent: parent} = state) do
    Logger.warn "[DBux.Transport.TCP #{inspect(self())}] TCP connection closed"
    send(parent, :dbux_transport_down)
    {:disconnect, {:error, :tcp_closed}, state}
  end


  # Handles asynchronously a line received from DBus Daemon if authentication
  # has succeeded.
  #
  # It alters state with `state: :authenticated`.
  @doc false
  def handle_info({:tcp, _sock, "OK " <> _}, %{state: :handshake, parent: parent} = state) do
    if @debug, do: Logger.debug "[DBux.Transport.TCP #{inspect(self())}] Authentication succeeded"
    # TODO send TCP to non-line mode
    send(parent, :dbux_authentication_succeeded)
    {:noreply, %{state | state: :authenticated}}
  end


  # Handles asynchronously a line received from DBus Daemon if authentication
  # has caused error.
  #
  # It always causes disconnect and alters state with `state: :init`.
  @doc false
  def handle_info({:tcp, _sock, "ERROR " <> reason}, %{state: :handshake, parent: parent} = state) do
    Logger.warn "[DBux.Transport.TCP #{inspect(self())}] Authentication error: #{reason}"
    send(parent, :dbux_authentication_error)
    {:disconnect, {:error, :dbux_authentication_error}, state}
  end


  # Handles asynchronously a line received from DBus Daemon if authentication
  # has failed.
  #
  # It always causes disconnect and alters state with `state: :handshake`.
  @doc false
  def handle_info({:tcp, _sock, "REJECTED " <> _, reason}, %{state: :handshake, parent: parent} = state) do
    Logger.warn "[DBux.Transport.TCP #{inspect(self())}] Authentication failed: #{reason}"
    send(parent, :dbux_authentication_failed)
    {:disconnect, {:error, :dbux_authentication_failed}, state}
  end


  # Handles asynchronous callback called when underlying TCP connection had an error.
  #
  # It returns `{:disconnect, {:error, :tcp_error}, state}`.
  @doc false
  def handle_info({:tcp, _, data}, %{state: :ready, parent: parent} = state) do
    if @debug, do: Logger.debug "[DBux.Transport.TCP #{inspect(self())}] TCP read: #{inspect(data)}"
    send(parent, {:dbux_transport_receive, data})
    {:noreply, state}
  end
end
