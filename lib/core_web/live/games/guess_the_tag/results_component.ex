defmodule CoreWeb.Games.GuessTheTag.ResultsComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="text-center">
        <a href={hd(@state.games).source} class="text-[#b4c7d9] hover:text-white" target="_blank">
          Image Source
        </a>
      </div>
      <br />

      <div class="flex flex-wrap gap-4">
        <%= for %{guesser: guesser, tags: tags, picked_by: picked_by, score: score} <- hd(@state.games).guesses do %>
          <div>
            <p><span class="text-yellow-500"><%= guesser %>'s</span> guess</p>
            <p>+<%= score %> for tags!</p>
            <p>+<%= 5 * length(picked_by) %> for deception!</p>

            <.button
              phx-click="pick"
              phx-target={@myself}
              style="width: 200px; text-align: left"
              disabled
            >
              <%= for {tag, correct?, tag_score} <- tags do %>
                <span class={class_color(correct?)}><%= tag %></span> +<%= tag_score %><br />
              <% end %>
            </.button>
            <p>
              Picked by: <br />
              <%= if picked_by != [] do %>
                <span class="text-yellow-500"><%= Enum.join(picked_by, ", ") %></span>
                <br />+<%= div(score, 2) %> to pickers!
              <% else %>
                nobody!
              <% end %>
            </p>
          </div>
        <% end %>
      </div>
      <br />

      <.button phx-click="next_game" {hide_if_not_owner(@current_player, @state.players)}>
        Continue
      </.button>
    </div>
    """
  end

  defp class_color(true), do: "text-green-500"
  defp class_color(false), do: "text-red-500"
end
