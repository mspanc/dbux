defmodule DBux.Bus do
  use Behaviour
  # @behaviour Connection

  defcallback init(any) ::
    {:ok, any} |
    {:stop, any}


  defmacro __using__(_) do
    quote location: :keep do
      @behaviour DBux.Bus

      @doc false
      def init(args) do
        {:ok, args}
      end


      defoverridable [init: 1]
    end
  end



  @doc """
  Starts a `DBux.Bus` process linked to the current process.

  This function is used to start a `DBux.Bus` process in a supervision tree.
  The process will be started by calling `init/1` in the callback module with
  the given argument.

  This function will return after `init/1` has returned in the spawned process.
  The return values are controlled by the `init/1` callback.

  See `GenServer.start_link/3` for more information.
  """
  @spec start_link(module, any, GenServer.options) :: GenServer.on_start
  def start_link(mod, args, opts \\ []) do
    # start(mod, args, opts, :link)
  end


  @doc """
  Starts a `Dbux.Bus` process without links (outside of a supervision tree).

  See `start_link/3` for more information.
  """
  @spec start(module, any, GenServer.options) :: GenServer.on_start
  def start(mod, args, opts \\ []) do
    # start(mod, args, opts, :nolink)
  end



end
