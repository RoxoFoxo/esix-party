defmodule CoreWeb.RoomLive do
  use CoreWeb, :live_view

  alias Core.Player
  alias Core.RoomRegistry

  @impl true
  def render(assigns) do
    ~H"""
    <p>Room name: <%= @state.name %></p>
    <p>Players:</p>
    <%= for player <- @state.players do %>
      <%= player.name %>
    <% end %>

    <%= if @current_player == nil do %>
      <.modal id="hi" show>
        <p>Please input your name:</p>
        <.simple_form for={@form} id="name-input" phx-change="validate" phx-submit="name-input">
          <:actions>
            <.input phx-remove="name-input" field={@form[:name]} type="text" label="Username" />
          </:actions>
        </.simple_form>
        <%= if @name_in_use? do %>
          Name is already in use!
        <% end %>
      </.modal>
    <% end %>
    """
  end

  @impl true
  def mount(%{"name" => name}, _session, socket) do
    # later I'll use this line for broadcasts
    # if connected?(socket), do: IO.puts("connected lol")

    if RoomRegistry.exists?(name) do
      Phoenix.PubSub.subscribe(Core.PubSub, name)

      server_pid = get_server_pid(name)

      {:ok,
       socket
       |> assign(%{
         server_pid: server_pid,
         state: GenServer.call(server_pid, :get_state),
         current_player: nil,
         name_in_use?: false,
         form: to_form(%{})
       })}
    else
      {:ok,
       socket
       |> put_flash(:error, "Room with code #{name} doesn't exist.")
       |> redirect(to: "/")}
    end
    |> IO.inspect()
  end

  @impl true
  def handle_event("validate", %{"name" => player_name}, socket) do
    {:noreply, assign(socket, :name_in_use?, name_in_use?(player_name, get_players(socket)))}
  end

  # create a block for "" names
  def handle_event("name-input", %{"name" => player_name}, socket) do
    players = get_players(socket)

    if name_in_use?(player_name, players) do
      {:noreply, assign(socket, :name_in_use?, true)}
    else
      owner? = players == []

      new_player_list = [%Player{name: player_name, owner?: owner?} | players]

      new_state =
        GenServer.call(
          socket.assigns.server_pid,
          {:update_player_list, socket.assigns.state.name, new_player_list}
        )

      {:noreply, assign(socket, %{state: new_state, current_player: player_name})}
    end
  end

  @impl true
  def handle_info({:new_state, new_state}, socket) do
    {:noreply, assign(socket, :state, new_state)}
  end

  @impl true
  def terminate(_reason, socket) do
    new_player_list =
      get_players(socket)
      |> Enum.reject(&(&1.name == socket.assigns.current_player))

    GenServer.call(
      socket.assigns.server_pid,
      {:update_player_list, socket.assigns.state.name, new_player_list}
    )
  end

  defp get_server_pid(name), do: GenServer.whereis({:via, Registry, {RoomRegistry, name}})

  defp get_players(socket), do: socket.assigns.state.players

  defp name_in_use?(player_name, players), do: Enum.any?(players, &(&1.name == player_name))
end
