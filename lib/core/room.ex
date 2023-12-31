defmodule Core.Room do
  @moduledoc false
  use GenServer, restart: :temporary

  alias Core.Games

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
  alias Core.Games.GuessTheTag

  def new do
    DynamicSupervisor.start_child(
      Core.RoomSupervisor,
      {__MODULE__, name: generate_new_name()}
    )
  end

  def start_link(name: {_, _, {_, name}} = registry_name) do
    GenServer.start_link(__MODULE__, %__MODULE__{name: name}, name: registry_name)
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

  def handle_call(
        {:game_setup, %{"blacklist" => blacklist} = params},
        _from,
        %{name: name} = state
      ) do
    {[game | _] = games, post_urls} = Games.setup(params)

    changes = %{
      games: games,
      post_urls: post_urls,
      status: game.type,
      blacklist: blacklist
    }

    new_state = Map.merge(state, changes)

    broadcast({:new_state, new_state}, name)
    {:reply, new_state, new_state, @fifteen_minutes}
  end

  def handle_call({:update_state, changes}, _from, %{name: name} = state) do
    new_state = Map.merge(state, changes)

    broadcast({:new_state, new_state}, name)
    {:reply, new_state, new_state, @fifteen_minutes}
  end

  @impl true
  def handle_cast(
        :start_timer,
        %{status: status, game_status: game_status, name: name, games: [game | _]} = state
      ) do
    time =
      case {status, game_status} do
        {:guess_the_tag, :pick} -> GuessTheTag.pick_timer(game.guesses)
        {:guess_the_tag, _} -> 61000
      end

    new_state = %{state | timer_ref: Process.send_after(self(), :timer, time)}
    broadcast({:new_state, new_state}, name)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(
        :timer,
        %{
          name: name,
          players: players,
          games: games,
          game_status: game_status,
          timer_ref: timer_ref
        } = state
      ) do
    changes =
      case game_status do
        :guess -> GuessTheTag.guess_changes(games, players, timer_ref)
        :pick -> GuessTheTag.pick_changes(games, players, timer_ref)
      end

    new_state = Map.merge(state, changes)
    broadcast({:new_state, new_state}, name)
    {:noreply, new_state}
  end

  def handle_info(:timeout, state) do
    {:stop, :timeout, state}
  end

  @impl true
  def terminate(:timeout, %{name: name} = state) do
    broadcast(:redirect_home, name)
    {:shutdown, state}
  end

  defp broadcast(msg, name), do: Phoenix.PubSub.broadcast(Core.PubSub, name, msg)
end
