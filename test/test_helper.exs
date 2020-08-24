ExUnit.start()
Application.ensure_all_started(:mox)

defmodule LoggerRemoteBehaviour do
  @callback log(any(), list(tuple())) :: {:ok, list(tuple())} | {:error, any()}
end

Mox.defmock(MockLogger, for: LoggerRemoteBehaviour)
