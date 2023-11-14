defmodule CoreWeb.FinalResultsComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

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

  def handle_event(
        "new_match",
        _params,
        %{assigns: %{server_pid: server_pid, state: %{players: players}}} = socket
      ) do
    reset_players = Enum.map(players, &Map.put(&1, :score, 0))
    update_state(socket, server_pid, %{status: :lobby, post_urls: [], players: reset_players})
  end

  def order_by_score(players),
    do: Enum.sort(players, fn %{score: score}, other -> score >= other end)
end
