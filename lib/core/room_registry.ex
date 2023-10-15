defmodule Core.RoomRegistry do
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_opts) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def exists?(name) do
    Registry.lookup(__MODULE__, name) !== []
  end
end
