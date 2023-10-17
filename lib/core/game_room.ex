defmodule Core.GameRoom do
  @moduledoc false
  use GenServer

  defstruct players: %{}

  alias Core.RoomRegistry

  def new do
    DynamicSupervisor.start_child(
      Core.RoomSupervisor,
      {__MODULE__, name: generate_new_name()}
    )
  end

  def start_link(name: {_, _, {_, name}} = registry_name) do
    GenServer.start_link(__MODULE__, %{name: name}, name: registry_name)
  end

  defp generate_new_name do
    name =
      1..6
      |> Enum.map(fn _ -> Enum.random(?A..?Z) end)
      |> to_string()

    if RoomRegistry.exists?(name) do
      generate_new_name()
    else
      {:via, Registry, {RoomRegistry, name}}
    end
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:get_name, _from, state) do
    {:reply, state.name, state}
  end
end
