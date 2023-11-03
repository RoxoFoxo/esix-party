defmodule CoreWeb.RoomLive do
  use CoreWeb, :live_view

  alias Core.RoomRegistry

  @components %{
    lobby: CoreWeb.LobbyComponent,
    guess_the_tag: CoreWeb.GuessTheTagComponent
  }

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={fetch_component(@state.status)}
      id="game_component"
      state={@state}
      server_pid={@server_pid}
      current_player={@current_player}
    />

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
      {:ok,
       socket
       |> put_flash(:error, "Room with name #{room_name} doesn't exist.")
       |> redirect(to: "/")}
    end
  end

  @impl true
  def handle_info({:new_state, new_state}, socket) do
    {:noreply, assign(socket, :state, new_state)}
  end

  def handle_info({:name_submit, assigns}, socket) do
    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def terminate(_reason, socket) do
    new_player_list =
      socket.assigns.state.players
      |> Enum.reject(&(&1.name == socket.assigns.current_player))

    GenServer.call(
      socket.assigns.server_pid,
      {:update_state, socket.assigns.state.name, %{players: new_player_list}}
    )
  end

  defp get_server_pid(name), do: GenServer.whereis({:via, Registry, {RoomRegistry, name}})

  defp fetch_component(status), do: @components[status]
end
