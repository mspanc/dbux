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


  def get_module_for_address("tcp:" <> rest) do
    params = Enum.reduce(String.split(rest, ","), [], fn(part, acc) ->
      [key, value] = String.split(part, "=", parts: 2)

      case key do
        "host" ->
          acc ++ [{:host, value}]

        "port" ->
          acc ++ [{:port, String.to_integer(value)}]

        _ ->
          acc
      end
    end)

    {:ok, {DBux.Transport.TCP, params}}
  end
end
