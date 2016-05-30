defmodule DBux.Transport.TCP do
  require Logger

  use Connection

  @behaviour DBux.Transport

  @connect_timeout   5000
  @reconnect_timeout 1000


  def start_link(parent, %{host: _host, port: _port} = options) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Start link")
    Connection.start_link(__MODULE__, {parent, options})
  end


  @doc false
  def init({parent, options}) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Init")
    {:ok, options
      |> Map.put(:parent, parent)
      |> Map.put(:sock, nil)
      |> Map.put(:state, :handshake)}
  end


  def connect(_, %{host: host, port: port} = state) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Connect: Connecting to #{host}:#{port}")
    case :gen_tcp.connect(to_char_list(host), port, [active: true, mode: :binary, packet: :line, keepalive: true, nodelay: true], @connect_timeout) do
      {:ok, sock} ->
        Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Connect: Successfully connected to #{host}:#{port}")
        {:ok, %{state | sock: sock, state: :handshake}}

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Connect: Failed to connect to #{host}:#{port}: #{inspect(reason)}")
        {:backoff, @reconnect_timeout, %{state | sock: nil, state: :handshake}}
    end
  end


  def disconnect(_, %{sock: sock} = state) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Disconnect")
    :ok = :gen_tcp.close(sock)
    {:backoff, @reconnect_timeout, %{state | sock: nil, state: :handshake}}
  end


  def do_connect(transport_proc) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Do connect: #{inspect(transport_proc)}")
    Connection.call(transport_proc, :connect)
  end


  def do_send(transport_proc, data) when is_binary(data) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Do send: #{inspect(transport_proc)}")
    Connection.call(transport_proc, {:send, data})
  end


  def do_begin(transport_proc) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Do begin: #{inspect(transport_proc)}")
    Connection.call(transport_proc, :begin)
  end


  @doc """
  Handles :connect calls when we are not connected.

  It instructs to connect and replies `:ok` to the sender.
  """
  def handle_call(:connect, _sender, %{sock: nil} = state) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Connect while disconnected")
    {:connect, :call, :ok, state}
  end


  @doc """
  Handles :connect calls when we are already connected.

  It replies `{:error, :already_connected}` to the sender.
  """
  def handle_call(:connect, _sender, state) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Connect while connected")
    {:reply, {:error, :already_connected}, state}
  end



  @doc """
  Handles :send calls when we are not connected.

  It replies `{:error, :not_connected}` to the sender.
  """
  def handle_call({:send, _}, _sender, %{sock: nil} = state) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Send while disconnected")
    {:reply, {:error, :not_connected}, state}
  end


  @doc """
  Handles :send calls when we are already connected.

  It replies `:ok` to the sender in case of success,
  `{:error, reason}` otherwise.
  """
  def handle_call({:send, data}, _sender, %{sock: sock} = state) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Send while connected")
    case :gen_tcp.send(sock, data) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to send data: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  @doc """
  Handles :begin calls when we are not connected.

  It replies `{:error, :not_connected}` to the sender.
  """
  def handle_call(:begin, _sender, %{sock: nil} = state) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Begin while disconnected")
    {:reply, {:error, :not_connected}, state}
  end


  @doc """
  Handles :begin calls when we are already connected.

  It replies `:ok` to the sender in case of success,
  `{:error, reason}` otherwise.
  """
  def handle_call(:begin, _sender, %{sock: sock} = state) do
    Logger.debug("[DBux.Transport.TCP #{inspect(self())}] Handle call: Begin while connected")
    case :gen_tcp.send(sock, "BEGIN\r\n") do
      :ok ->
        :inet.setopts(sock, [packet: :raw, active: true])
        {:reply, :ok, %{state | state: :ready}}

      {:error, reason} ->
        Logger.warn("[DBux.Connection #{inspect(self())}] Failed to begin: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end


  @doc """
  Handles asynchronous callback called when underlying TCP connection was closed.

  It returns `{:disconnect, {:error, :tcp_closed}, state}`.
  """
  def handle_info({:tcp_closed, _}, %{parent: parent} = state) do
    Logger.warn "[DBux.Connection #{inspect(self())}] TCP connection closed"
    send(parent, :transport_down)
    {:disconnect, {:error, :tcp_closed}, state}
  end


  @doc """
  Handles asynchronously a line received from DBus Daemon if authentication
  has succeeded.

  It alters state with `state: :authenticated`.
  """
  def handle_info({:tcp, _sock, "OK " <> _}, %{state: :handshake, parent: parent} = state) do
    Logger.debug "[DBux.Connection #{inspect(self())}] Authentication succeeded"
    # TODO send TCP to non-line mode
    send(parent, :authentication_succeeded)
    {:noreply, %{state | state: :authenticated}}
  end


  @doc """
  Handles asynchronously a line received from DBus Daemon if authentication
  has caused error.

  It always causes disconnect and alters state with `state: :init`.
  """
  def handle_info({:tcp, _sock, "ERROR " <> reason}, %{state: :handshake, parent: parent} = state) do
    Logger.warn "[DBux.Connection #{inspect(self())}] Authentication error: #{reason}"
    send(parent, :authentication_error)
    {:disconnect, {:error, :authentication_error}, state}
  end


  @doc """
  Handles asynchronously a line received from DBus Daemon if authentication
  has failed.

  It always causes disconnect and alters state with `state: :handshake`.
  """
  def handle_info({:tcp, _sock, "REJECTED " <> _, reason}, %{state: :handshake, parent: parent} = state) do
    Logger.warn "[DBux.Connection #{inspect(self())}] Authentication failed: #{reason}"
    send(parent, :authentication_failed)
    {:disconnect, {:error, :authentication_failed}, state}
  end


  @doc """
  Handles asynchronously a line received from DBus Daemon if authentication
  has failed.

  It always causes disconnect and alters state with `state: :handshake`.
  """
  def handle_info({:tcp, _sock, "REJECTED " <> _, reason}, %{state: :handshake, parent: parent} = state) do
    Logger.warn "[DBux.Connection #{inspect(self())}] Authentication failed: #{reason}"
    send(parent, :authentication_failed)
    {:disconnect, {:error, :authentication_failed}, state}
  end


  @doc """
  Handles asynchronous callback called when underlying TCP connection had an error.

  It returns `{:disconnect, {:error, :tcp_error}, state}`.
  """
  def handle_info({:tcp, _, data}, %{state: :ready, parent: parent} = state) do
    Logger.debug "[DBux.Connection #{inspect(self())}] TCP read: #{inspect(data)}"
    send(parent, {:receive, data})
    {:noreply, state}
  end
end
