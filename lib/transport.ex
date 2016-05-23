defmodule DBux.Transport do
  @callback start_link(pid, map) ::
    GenServer.on_start


  @callback do_connect(pid) ::
    :ok |
    {:error, any}

  @callback do_send(pid, binary) ::
    :ok |
    {:error, any}

  @callback do_begin(pid) ::
    :ok |
    {:error, any}
end
