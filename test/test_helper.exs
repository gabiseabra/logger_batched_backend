ExUnit.start()
Application.ensure_all_started(:mox)

defmodule LoggerBatchedBackendBehaviour do
  @callback log(list(tuple()), any()) :: {:ok, list(tuple())} | {:error, any()}
end

Mox.defmock(MockLogger, for: LoggerBatchedBackendBehaviour)
