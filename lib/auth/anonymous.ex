defmodule DBux.Auth.Anonymous do
  require Logger
  use GenServer

  @behaviour DBux.Auth


  def start_link(_parent, options) do
    Logger.debug("[DBux.Auth.Anonymous #{inspect(self())}] Start link")
    Connection.start_link(__MODULE__, options)
  end


  @doc false
  def init(_options) do
    Logger.debug("[DBux.Auth.Anonymous #{inspect(self())}] Init")
    {:ok, %{}}
  end


  def do_handshake(auth_proc, transport_mod, transport_proc) do
    GenServer.call(auth_proc, {:handshake, {transport_mod, transport_proc}})
  end


  def handle_call({:handshake, {transport_mod, transport_proc}}, _sender, state) do
    Logger.debug("[DBux.Auth.Anonymous #{inspect(self())}] Handle call: Handshake")
    case transport_mod.do_send(transport_proc, "\0AUTH ANONYMOUS 527562792044427573\r\n") do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
end
