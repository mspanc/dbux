defmodule DBux.Transport.TCP do
  use Behaviour
  @behaviour DBux.Transport

  @default_connect_timeout 5000

  def connect(opts) when is_list(opts) do
    parsed_opts = parse_opts(opts)

    :gen_tcp.connect(to_char_list(parsed_opts[:hostname]), parsed_opts[:port], [active: true, mode: :binary, packet: :line, keepalive: true, nodelay: true], @default_connect_timeout)
  end


  defp parse_opts(opts) do
    %{}
    |> extract_mandatory_string_opt(opts, :hostname)
    |> extract_mandatory_integer_opt(opts, :port, 1, 65535)
  end


  defp extract_mandatory_string_opt(acc, opts, key) do
    if List.keymember?(opts, key, 0) do
      if is_binary(opts[key]) do
        Map.put(acc, key, opts[key])

      else
        throw {:badopts, key, :invalidtype}
      end

    else
      throw {:badopts, key, :missing}
    end
  end


  defp extract_mandatory_integer_opt(acc, opts, key, range_min \\ nil, range_max \\ nil) do
    if List.keymember?(opts, key, 0) do
      if is_integer(opts[key]) do
        cond do
          is_nil(range_min) and is_nil(range_max) ->
            Map.put(acc, key, opts[key])

          is_nil(range_min) ->
            if opts[key] >= range_min do
              Map.put(acc, key, opts[key])
            else
              throw {:badopts, key, :outofrange}
            end

          is_nil(range_max) ->
            if opts[key] <= range_min do
              Map.put(acc, key, opts[key])
            else
              throw {:badopts, key, :outofrange}
            end

          true ->
            if opts[key] >= range_min and opts[key] <= range_max do
              Map.put(acc, key, opts[key])
            else
              throw {:badopts, key, :outofrange}
            end
        end

      else
        throw {:badopts, key, :invalidtype}
      end

    else
      throw {:badopts, key, :missing}
    end
  end


  def disconnect(socket) do
    :gen_tcp.close(socket)
  end
end
