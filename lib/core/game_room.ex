defmodule Core.GameRoom do
  @moduledoc false
  use GenServer, restart: :temporary

  @enforce_keys [:name]
  defstruct [
    :name,
    :game_status,
    :games,
    :post_urls,
    :timer_ref,
    :blacklist,
    players: [],
    status: :lobby
  ]

  @one_minute 60000
  @fifteen_minutes 900_000

  alias Core.RoomRegistry

  def new do
    DynamicSupervisor.start_child(
      Core.RoomSupervisor,
      {__MODULE__, name: generate_new_name()}
    )
  end

  def start_link(name: {_, _, {_, name}} = registry_name) do
    GenServer.start_link(__MODULE__, %Core.GameRoom{name: name}, name: registry_name)
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
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:get_name, _from, %{name: room_name} = state) do
    {:reply, room_name, state, @one_minute}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state, @fifteen_minutes}
  end

  def handle_call({:update_state, changes}, _from, state) do
    new_state = Map.merge(state, changes)

    broadcast({:new_state, new_state}, state.name)
    {:reply, new_state, new_state, @fifteen_minutes}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :timeout, state}
  end

  @impl true
  def terminate(:timeout, state) do
    {:shutdown, state}
  end

  defp broadcast(msg, name) do
    Phoenix.PubSub.broadcast(Core.PubSub, name, msg)
  end
end
