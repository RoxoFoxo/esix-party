defmodule CoreWeb.RoomLive do
  use CoreWeb, :live_view

  import CoreWeb.RoomUtils

  alias Core.RoomRegistry

  @components %{
    lobby: CoreWeb.LobbyComponent,
    guess_the_tag: CoreWeb.Games.GuessTheTagComponent,
    final_results: CoreWeb.FinalResultsComponent
  }

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @state do %>
      <div class="grid gap-4 grid-cols-5">
        <div class="bg-blue-900/50 rounded-xl p-5 mb-auto sticky top-10 border-2 border-blue-950">
          <.live_component
            module={CoreWeb.ScoreboardComponent}
            id="scoreboard_component"
            players={@state.players}
            status={@state.status}
          />
        </div>

        <div class="max-w-3xl col-span-3 mx-auto mb-auto bg-blue-900/50 rounded-xl p-5 border-2 border-blue-950">
          <%= if @state.status != :lobby do %>
            <p
              title={add_default_blacklist(@state.blacklist)}
              class="text-[#b4c7d9] hover:text-white select-none"
            >
              Hover to see blacklist
            </p>
          <% end %>

          <.live_component
            module={fetch_component(@state.status)}
            id="room_component"
            state={@state}
            server_pid={@server_pid}
            current_player={@current_player}
            time_remaining={@time_remaining}
          />
        </div>
      </div>
    <% end %>

    <%= if @current_player == nil do %>
      <.live_component
        module={CoreWeb.NameInputComponent}
        id="name_input_component"
        state={@state}
        server_pid={@server_pid}
      />
    <% end %>
    """
  end

  @impl true
  def mount(%{"name" => room_name}, _session, socket) do
    if RoomRegistry.exists?(room_name) do
      if connected?(socket), do: Phoenix.PubSub.subscribe(Core.PubSub, room_name)

      server_pid = get_server_pid(room_name)

      {:ok,
       socket
       |> assign(%{
         page_title: room_name,
         server_pid: server_pid,
         state: GenServer.call(server_pid, :get_state),
         current_player: nil,
         time_remaining: 0
       })}
    else
      {:ok, redirect_to_home(socket, {:error, "Room with name #{room_name} doesn't exist."})}
    end
  end

  @impl true
  def handle_event(
        "next_game",
        _params,
        %{assigns: %{state: %{games: [_current | games]}}} = socket
      ) do
    new_status =
      case games do
        [game | _] -> game.type
        [] -> :final_results
      end

    changes = %{
      games: games,
      status: new_status,
      game_status: nil
    }

    {:noreply, update_state(socket, changes)}
  end

  @impl true
  def handle_info({:new_state, new_state}, socket) do
    {:noreply, assign(socket, :state, new_state)}
  end

  def handle_info(:redirect_home, socket) do
    {:noreply, socket |> assign(:state, %{}) |> redirect_to_home()}
  end

  def handle_info({:name_submit, assigns}, socket) do
    {:noreply, assign(socket, assigns)}
  end

  def handle_info(:tick, %{assigns: %{state: %{timer_ref: nil}}} = socket) do
    {:noreply, assign(socket, :time_remaining, 0)}
  end

  def handle_info(
        :tick,
        %{assigns: %{state: %{timer_ref: timer_ref}}} = socket
      ) do
    time_remaining =
      if time = Process.read_timer(timer_ref) do
        Process.send_after(self(), :tick, 1000)

        time
        |> div(1000)
        |> ceil()
      else
        0
      end

    {:noreply, assign(socket, :time_remaining, time_remaining)}
  end

  @impl true
  def terminate(
        _reason,
        %{
          assigns: %{
            current_player: current_player,
            state: %{players: players}
          }
        } = socket
      )
      when current_player != nil do
    new_players = Enum.reject(players, &(&1.name == current_player))

    case is_owner?(current_player, players) do
      true -> List.update_at(new_players, -1, &Map.put(&1, :owner?, true))
      false -> new_players
    end
    |> then(&update_state(socket, %{players: &1}))
  end

  def terminate(_reason, _socket), do: :ok

  @blacklist_hover_first "Blacklisted tags: "
  @blacklist_hover_tags "animated gore scat watersports young loli shota"

  defp add_default_blacklist("") do
    @blacklist_hover_first <> @blacklist_hover_tags
  end

  defp add_default_blacklist(blacklist) do
    @blacklist_hover_first <> blacklist <> " " <> @blacklist_hover_tags
  end

  defp get_server_pid(name), do: GenServer.whereis({:via, Registry, {RoomRegistry, name}})

  defp fetch_component(status), do: @components[status]
end
