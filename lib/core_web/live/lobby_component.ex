defmodule CoreWeb.LobbyComponent do
  use CoreWeb, :live_component

  alias Core.E621Client

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p>Room name: <%= @state.name %></p>
      <p>Players:</p>
      <%= for player <- Enum.reverse(@state.players) do %>
        <%= player.name %> <br />
      <% end %>

      <.button phx-click="start" phx-target={@myself}>START</.button>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("start", _params, socket) do
    posts = E621Client.get_random_posts(1)

    GenServer.call(
      socket.assigns.server_pid,
      {:update_state, socket.assigns.state.name, %{posts: posts, status: "post1"}}
    )

    {:noreply, socket}
  end
end
