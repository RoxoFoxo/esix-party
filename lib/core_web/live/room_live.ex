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
      <.live_component
        module={fetch_component(@state.status)}
        id="room_component"
        state={@state}
        server_pid={@server_pid}
        current_player={@current_player}
      />
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
      Phoenix.PubSub.subscribe(Core.PubSub, room_name)

      server_pid = get_server_pid(room_name)

      {:ok,
       socket
       |> assign(%{
         server_pid: server_pid,
         state: GenServer.call(server_pid, :get_state),
         current_player: nil
       })}
    else
      {:ok, redirect_to_home(socket, {:error, "Room with name #{room_name} doesn't exist."})}
    end
  end

  @impl true
  def handle_event(
        "next_game",
        _params,
        %{assigns: %{server_pid: server_pid, state: %{games: [_current | games]}}} = socket
      ) do
    new_status =
      case games do
        [] -> :final_results
        _ -> get_new_status(games)
      end

    changes = %{games: games, status: new_status, game_status: nil}

    update_state(socket, server_pid, changes)
  end

  @impl true
  def handle_info({:new_state, new_state}, socket) do
    {:noreply, assign(socket, :state, new_state)}
    |> IO.inspect()
  end

  def handle_info({:name_submit, assigns}, socket) do
    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def terminate(
        _reason,
        %{
          assigns: %{
            server_pid: server_pid,
            current_player: current_player,
            state: %{players: players}
          }
        } = socket
      )
      when current_player do
    new_players = Enum.reject(players, &(&1.name == current_player))

    update_state(socket, server_pid, %{players: new_players})
  end

  def terminate(_reason, _socket), do: :ok

  defp get_new_status(games) do
    games
    |> Enum.at(0)
    |> then(& &1.game_type)
  end

  defp get_server_pid(name), do: GenServer.whereis({:via, Registry, {RoomRegistry, name}})

  defp fetch_component(status), do: @components[status]
end
