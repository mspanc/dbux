defmodule DBux.Auth do
  @callback start_link(pid, map) ::
    GenServer.on_start

  @callback do_handshake(module, module, pid) ::
    :ok |
    {:error, any}


  def get_module_for_method(:anonymous) do
    {:ok, {DBux.Auth.Anonymous, []}}
  end
end
