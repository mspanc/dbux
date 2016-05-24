defmodule DBux.Serial do
  @spec start_link(list) :: GenServer.on_start
  def start_link(opts \\ []) do
    Agent.start_link(fn -> 1 end, opts)
  end


  @spec retreive(pid) :: number
  def retreive(agent) when is_pid(agent) do
    Agent.get_and_update(agent, fn(state) ->
      cond do
        state == 0xFFFFFFFF ->
          {state, 1}

        true ->
          {state, state+1}
      end
    end)
  end
end
