defmodule DBux.Transport do
  use Behaviour

  @doc """
  Called when connection attempt is made.

  It should spawn a separate process that handles actual connection,
  including it's all callbacks regarding unexpected disconnects etc.

  Returning `{:ok, pid}` will be understood by calee as a success
  and `pid` will be passed to all of the remaining callbacks.

  Returning `{:error, reason}` will be understood by calee as failure.
  """
  defcallback connect(any) ::
    {:ok, any} |
    {:error, any}


  defcallback disconnect(any) ::
    :ok |
    {:error, any}

end
