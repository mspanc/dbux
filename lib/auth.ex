defmodule DBux.Auth do
  @callback start_link(pid, map) ::
    GenServer.on_start

  @callback do_handshake(module, module, pid) ::
    :ok |
    {:error, any}
end
