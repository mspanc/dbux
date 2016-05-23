defmodule DBux.Bus do
  require Logger

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

    {:ok, transport_proc} = transport_mod.start_link(transport_opts)
    {:ok, auth_proc} = auth_mod.start_link(auth_opts)

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
            Logger.debug("[DBux.Bus #{inspect(self())}] Authenticated")
            {:ok, %{state | state: :authenticated}}

          {:error, _} ->
            Logger.debug("[DBux.Bus #{inspect(self())}] Failed to authenticate")
            {:backoff, @reconnect_timeout, %{state | state: :init}}
        end

      {:error, _} ->
        Logger.debug("[DBux.Bus #{inspect(self())}] Failed to connect")
        {:backoff, @reconnect_timeout, %{state | state: :init}}
    end
  end


end
