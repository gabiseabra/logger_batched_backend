defmodule LoggerBatchedBackendTest do
  use ExUnit.Case

  import Mox
  require Logger

  setup do
    {:ok, _} = Logger.add_backend(LoggerBatchedBackend, flush: true)

    on_exit(fn ->
      Logger.remove_backend(LoggerBatchedBackend, flush: true)
    end)

    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  @tag capture_log: true
  test "calls handler function on flush" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        handler: {MockLogger, :log},
        handler_options: %{test: 123}
      )

    MockLogger
    |> expect(:log, fn [{:info, "eyy", _timestamp, _metadata}], %{test: 123} -> {:ok, []} end)

    Logger.info("eyy")
    Logger.flush()
  end

  @tag capture_log: true
  test "flushes logs periodically" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        handler: {MockLogger, :log},
        handler_options: %{test: 123},
        flush_interval: 10
      )

    MockLogger
    |> expect(:log, fn [{:info, "eyy", _, _}], %{test: 123} ->
      {:ok, []}
    end)
    |> expect(:log, fn [{:info, "lmao", _, _}], %{test: 123} ->
      {:ok, []}
    end)

    Logger.info("eyy")

    :timer.sleep(20)

    Logger.info("lmao")

    :timer.sleep(20)
  end

  @tag capture_log: true
  test "sends all messages in queue" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        handler: {MockLogger, :log},
        handler_options: %{test: 123},
        flush_interval: 10
      )

    MockLogger
    |> expect(:log, fn [{:info, "eyy", _, _}, {:info, "lmao", _, _}], %{test: 123} ->
      {:ok, []}
    end)

    Logger.info("eyy")
    Logger.info("lmao")

    :timer.sleep(20)
  end

  @tag capture_log: true
  test "requeues messages" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        handler: {MockLogger, :log},
        handler_options: %{test: 123}
      )

    MockLogger
    |> expect(:log, fn [{:info, "eyy", _, _} | rest], %{test: 123} ->
      {:ok, rest}
    end)
    |> expect(:log, fn [{:info, "lmao", _, _}], %{test: 123} ->
      {:ok, []}
    end)

    Logger.info("eyy")
    Logger.info("lmao")

    Logger.flush()
    Logger.flush()

    :timer.sleep(10)
  end

  @tag capture_log: true
  test "flushes all messages immediately when queue is full" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        handler: {MockLogger, :log},
        handler_options: %{test: 123},
        flush_interval: nil,
        batch_size: 2
      )

    MockLogger
    |> expect(:log, fn [{:info, "eyy", _, _}, {:info, "lmao", _, _}], %{test: 123} ->
      {:ok, []}
    end)

    Logger.info("eyy")
    Logger.info("lmao")

    :timer.sleep(10)
  end

  @tag capture_log: true
  test "filters by log level" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        handler: {MockLogger, :log},
        handler_options: %{test: 123},
        level: :warn
      )

    MockLogger
    |> expect(:log, fn [{:warn, "warn", _, _}, {:error, "error", _, _}], %{test: 123} ->
      {:ok, []}
    end)

    Logger.debug("debug")
    Logger.info("info")
    Logger.warn("warn")
    Logger.error("error")

    Logger.flush()

    :timer.sleep(10)
  end

  @tag capture_log: true
  test "overrides timestamp with method" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        handler: {MockLogger, :log},
        handler_options: %{test: 123},
        level: :info,
        timestamp: fn -> "2020-01-01" end
      )

    MockLogger
    |> expect(:log, fn [{:info, "eyy", "2020-01-01", _}], %{test: 123} ->
      {:ok, []}
    end)

    Logger.info("eyy")

    Logger.flush()

    :timer.sleep(10)
  end
end
