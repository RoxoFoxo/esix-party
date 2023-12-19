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
        <p><span class="text-yellow-500"><%= name %></span> <%= to_string(score) %></p>
      <% end %>
      <hr />

      <%= for %{guesser: guesser, tags: tags, picked_by: picked_by} <- hd(@state.games).guesses do %>
        <p><span class="text-yellow-500"><%= guesser %>'s</span> guess</p>
        <.button phx-click="pick" phx-target={@myself} style="width: 200px; text-align: left" disabled>
          <%= for tag <- tags do %>
            <%= tag %> <br />
          <% end %>
        </.button>
        <p>
          Picked by: <br />
          <%= if picked_by != [] do %>
            <span class="text-yellow-500"><%= Enum.join(picked_by, ", ") %></span>
          <% else %>
            nobody!
          <% end %>
        </p>
        <hr />
      <% end %>

      <.button phx-click="next_game" {hide_if_not_owner(@current_player, @state.players)}>
        Continue
      </.button>
    </div>
    """
  end
end
