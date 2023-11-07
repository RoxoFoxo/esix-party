defmodule CoreWeb.Games.GuessTheTag.ResultsComponent do
  use CoreWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <a href={hd(@state.games).source} target="_blank">Source</a>
      <hr />

      <%= for %{name: name, score: score} <- @state.players do %>
        <%= name <> " score: " <> to_string(score) %> <br />
      <% end %>
      <br />

      <%= for {guesser, %{tags: tags, picked_by: picked_by}}  <- hd(@state.games).guesses do %>
        <.button phx-click="pick" phx-target={@myself} style="width: 200px; text-align: left" disabled>
          <%= guesser %> <br />
          <%= for tag <- tags do %>
            <%= tag %> <br />
          <% end %>
        </.button>
        <p>Picked by: <br /><%= Enum.join(picked_by, ", ") %></p>
        <hr />
      <% end %>

      <.button phx-click="next_game">Continue</.button>
    </div>
    """
  end
end
