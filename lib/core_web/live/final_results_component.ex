defmodule CoreWeb.FinalResultsComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

  def render(assigns) do
    ~H"""
    <div>
      <%= for post <- @state.post_urls do %>
        <a href={post.source} target="_blank"><img src={post.image} /></a>
        <br />
      <% end %>

      <p>Results!</p>
      <%= for player <- order_by_score(@state.players) do %>
        <%= player.name <> " " <> to_string(player.score) %> <br />
      <% end %>

      <.button
        phx-click="new_match"
        phx-target={@myself}
        {hide_if_not_owner(@current_player, @players)}
      >
        New match
      </.button>
    </div>
    """
  end

  def handle_event(
        "new_match",
        _params,
        %{assigns: %{state: %{players: players}}} = socket
      ) do
    changes = %{
      status: :lobby,
      post_urls: [],
      players: Enum.map(players, &Map.put(&1, :score, 0))
    }

    {:noreply, update_state(socket, changes)}
  end

  def order_by_score(players),
    do: Enum.sort(players, fn %{score: score}, other -> score >= other end)
end
