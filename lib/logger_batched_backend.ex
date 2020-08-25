defmodule LoggerBatchedBackend do
  @moduledoc """
  Logger backend for sending messages in batches with a custom handler.
  """

  @behaviour :gen_event

  @options ~w(flush_interval batch_size handler handler_options timestamp level)a

  @initial_state %{
    queue: [],
    timer: nil,
    flush_interval: 1000 * 15,
    batch_size: 10,
    handler: nil,
    handler_options: [],
    timestamp: nil,
    level: :debug
  }

  def init(__MODULE__) do
    configure([], @initial_state)
  end

  def init({__MODULE__, name}) do
    Application.get_env(:logger, name, [])
    |> configure(@initial_state)
  end

  def handle_call({:configure, opts}, state) do
    {:ok, new_state} = configure(opts, state)
    {:ok, {:ok, new_state}, new_state}
  end

  def handle_event({level, _group_leader, {Logger, message, timestamp, metadata}}, state) do
    if should_log?(state, level) do
      timestamp = get_timestamp(state) || timestamp
      enqueue(state, {level, message, timestamp, metadata})
    else
      {:ok, state}
    end
  end

  def handle_event(:flush, state), do: flush!(state)

  def handle_info(:flush, state) do
    state
    |> flush!()
    |> schedule_flush()
  end

  def handle_info(_term, state), do: {:ok, state}

  defp enqueue(%{queue: queue, batch_size: batch_size} = state, msg)
       when length(queue) + 1 < batch_size,
       do: {:ok, %{state | queue: queue ++ [msg]}}

  defp enqueue(%{queue: queue} = state, msg) do
    flush!(%{state | queue: queue ++ [msg]}) |> schedule_flush()
  end

  defp schedule_flush({:ok, state}), do: schedule_flush(state)
  defp schedule_flush({:error, _} = error), do: error

  defp schedule_flush(%{flush_interval: nil} = state), do: {:ok, state}

  defp schedule_flush(%{flush_interval: interval, timer: timer} = state) do
    if timer, do: Process.cancel_timer(timer, async: true)
    timer = Process.send_after(self(), :flush, interval)
    {:ok, %{state | timer: timer}}
  end

  defp flush!(%{queue: []} = state), do: {:ok, state}

  defp flush!(%{handler: {module, method}, handler_options: opts, queue: queue} = state) do
    with {:ok, queue} <- apply(module, method, [queue, opts]) do
      {:ok, %{state | queue: queue}}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp flush!(state), do: {:ok, state}

  defp should_log?(%{level: min_level}, level),
    do: Logger.compare_levels(level, min_level) != :lt

  defp get_timestamp(%{timestamp: {module, method}}), do: apply(module, method, [])
  defp get_timestamp(%{timestamp: fun}) when is_function(fun), do: fun.()
  defp get_timestamp(_), do: nil

  defp configure(opts, state) do
    {:ok, new_state} =
      opts
      |> Enum.into(%{})
      |> Map.take(@options)
      |> Enum.into(state)
      |> schedule_flush()

    {:ok, new_state}
  end
end
