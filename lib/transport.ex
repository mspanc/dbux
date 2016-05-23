defmodule DBux.Transport do
  @callback start_link(map) ::
    GenServer.on_start


  @callback do_connect(pid) ::
    :ok |
    {:error, any}

  @callback do_send(pid, binary) ::
    :ok |
    {:error, any}
end
