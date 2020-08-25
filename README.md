# LoggerBatchedBackend

Service agnostic logger backend for elixir that handles batching and retries.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `logger_batched_backend` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logger_batched_backend, "~> 0.1.0"}
  ]
end
```

## Configuration 

```elixir
use Mix.Config

config :logger, backends: [{LoggerBatchedBackend, :example}]

config :logger, :example,
  # [optional] Maximum interval in milliseconds to send batches. Logs are flushed periodically
  # within this interval. Use `nil` to disable this feature.
  # default: 15000
  flush_interval: 1000 * 15,
  # [optional] Maximum batch size. Logs are flushed when the queue reaches this many messages.
  # default: 10
  batch_size: 10,
  # [optional] Minimum log level.
  # default: :debug
  level: :debug
  # [optional] A function that returns the current time, used to override a message's timestamp
  # at the time of logging.
  # default: nil
  timestamp: {Timex, :now},
  # [required] Function that handles logging, see signature below.
  handler: {ExampleHandler, :log},
  # [required] Options passed to the second argument to the `handler` function.
  handler_options: %{
    # ...
  }
```

The configuration must specify `handler_options` and a `handler` method to handle logging as follows:

```elixir
defmodule ExampleHandler do
  @spec log(list(tuple()), any()) :: {:ok, list(tuple())} | {:error, any()}
  def log(batch, config) do
    # ... send messages to some log management service
    {:ok, []}
  end
end
```

The method takes a list of message tuples `{level, message, timestamp, metadata}` and `handler_options`,
and returns an ok tuple with a list of messages that have not been handled to requeue.
This allows for retries without having to handle async tasks:

```elixir
defmodule ExampleHandler do
  @retry 5

  def log(batch, config) do
    with :ok <- do_log(batch) do
      {:ok, []}
    else
      _ -> {:ok, retry(batch)}
    end
  end

  defp retry([]), do: []
  defp retry([{_, _, _, _, @retry} | rest]), do: raise "failed to log message #{@retry} times!"
  defp retry([{lvl, msg, ts, md, tries} | rest]), do: [{lvl, msg, ts, md, tries + 1}] ++ retry(rest)
  defp retry([{lvl, msg, ts, md} | rest]), do: [{lvl, msg, ts, md, 1}] ++ retry(rest)
end

