ExUnit.start()
Application.ensure_all_started(:mox)

defmodule LoggerBatchedBackendBehaviour do
  @callback log(any(), list(tuple())) :: {:ok, list(tuple())} | {:error, any()}
end

Mox.defmock(MockLogger, for: LoggerBatchedBackendBehaviour)
