defmodule CoreWeb.Games.GuessTheTag.ResultsComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <a href={hd(@state.games).source} target="_blank">Source</a>
      <hr />

      <p>Scores:</p>
      <%= for %{name: name, score: score} <- @state.players do %>
        <%= name <> " " <> to_string(score) %> <br />
      <% end %>
      <hr />

      <%= for %{guesser: guesser, tags: tags, picked_by: picked_by} <- hd(@state.games).guesses do %>
        <%= guesser %>'s guess <br />
        <.button phx-click="pick" phx-target={@myself} style="width: 200px; text-align: left" disabled>
          <%= for tag <- tags do %>
            <%= tag %> <br />
          <% end %>
        </.button>
        <p>Picked by: <br /><%= Enum.join(picked_by, ", ") %></p>
        <hr />
      <% end %>

      <.button phx-click="next_game" {hide_if_not_owner(@current_player, @state.players)}>
        Continue
      </.button>
    </div>
    """
  end
end
