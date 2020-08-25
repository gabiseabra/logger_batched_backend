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
  test "calls client function on flush" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        client: {MockLogger, :log},
        client_options: %{test: 123}
      )

    MockLogger
    |> expect(:log, fn %{test: 123}, [{:info, "eyy", _timestamp, _metadata}] -> {:ok, []} end)

    Logger.info("eyy")
    Logger.flush()
  end

  @tag capture_log: true
  test "flushes logs periodically" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        client: {MockLogger, :log},
        client_options: %{test: 123},
        flush_interval: 10
      )

    MockLogger
    |> expect(:log, fn %{test: 123}, [{:info, "eyy", _, _}] ->
      {:ok, []}
    end)
    |> expect(:log, fn %{test: 123}, [{:info, "lmao", _, _}] ->
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
        client: {MockLogger, :log},
        client_options: %{test: 123},
        flush_interval: 10
      )

    MockLogger
    |> expect(:log, fn %{test: 123}, [{:info, "eyy", _, _}, {:info, "lmao", _, _}] ->
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
        client: {MockLogger, :log},
        client_options: %{test: 123}
      )

    MockLogger
    |> expect(:log, fn %{test: 123}, [{:info, "eyy", _, _} | rest] ->
      {:ok, rest}
    end)
    |> expect(:log, fn %{test: 123}, [{:info, "lmao", _, _}] ->
      {:ok, []}
    end)

    Logger.info("eyy")
    Logger.info("lmao")

    Logger.flush()
    Logger.flush()
  end

  @tag capture_log: true
  test "flushes all messages immediately when queue is full" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        client: {MockLogger, :log},
        client_options: %{test: 123},
        flush_interval: nil,
        max_batch: 2
      )

    MockLogger
    |> expect(:log, fn %{test: 123}, [{:info, "eyy", _, _}, {:info, "lmao", _, _}] ->
      {:ok, []}
    end)

    Logger.info("eyy")
    Logger.info("lmao")

    :timer.sleep(100)
  end

  @tag capture_log: true
  test "filters by log level" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        client: {MockLogger, :log},
        client_options: %{test: 123},
        level: :warn
      )

    MockLogger
    |> expect(:log, fn %{test: 123}, [{:warn, "warn", _, _}, {:error, "error", _, _}] ->
      {:ok, []}
    end)

    Logger.debug("debug")
    Logger.info("info")
    Logger.warn("warn")
    Logger.error("error")

    Logger.flush()
  end

  @tag capture_log: true
  test "overrides timestamp with method" do
    {:ok, _} =
      Logger.configure_backend(LoggerBatchedBackend,
        client: {MockLogger, :log},
        client_options: %{test: 123},
        level: :warn,
        timestamp: fn -> "2020-01-01" end
      )

    MockLogger
    |> expect(:log, fn %{test: 123}, [{:warn, "eyy", "2020-01-01", _}] ->
      {:ok, []}
    end)

    Logger.debug("eyy")

    Logger.flush()
  end
end
