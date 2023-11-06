defmodule CoreWeb.FinalResultsComponent do
  use CoreWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <%= for post <- @state.post_urls do %>
        <a href={post.source} target="_blank"><img src={post.image} /></a>
      <% end %>

      <p>Results!</p>
      <%= for player <- order_by_score(@state.players) do %>
        <%= player.name <> " " <> to_string(player.score) %> <br />
      <% end %>

      <.button phx-click="new_match" phx-target={@myself}>New match</.button>
    </div>
    """
  end

  def handle_event("new_match", _params, %{assigns: %{server_pid: server_pid}} = socket) do
    GenServer.call(server_pid, {:update_state, %{status: :lobby, post_urls: []}})

    {:noreply, socket}
  end

  def order_by_score(players),
    do: Enum.sort(players, fn %{score: score}, other -> score >= other end)
end
