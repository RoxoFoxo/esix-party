Mox.defmock(Core.E621Mock, for: Core.E621Client)

Application.put_env(:e621, :api, Core.E621Mock)

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, :manual)
