defmodule CoreWeb.ScoreboardComponent do
  use CoreWeb, :live_component

  @text_yellow "text-yellow-500"
  @text_green "text-green-500"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p class="text-center">
        <%= if @status == :lobby, do: "Players", else: "Scoreboard" %>
      </p>
      <div class="flex flex-col">
        <%= for %{name: name, owner?: owner?, score: score} <- sort_players(@players) do %>
          <div class="flex flex-row gap-x-2 justify-between">
            <div>
              <span class={name_color(name, @status, @game_status, @games)}><%= name %></span>
              <%= if owner?, do: " 👑" %>
            </div>
            <div>
              <%= if @status != :lobby, do: score %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp sort_players(players) do
    case Enum.any?(players, &(&1.score != 0)) do
      true -> Enum.sort_by(players, & &1.score, :desc)
      false -> Enum.reverse(players)
    end
  end

  defp name_color(name, :guess_the_tag, :guess, [%{guesses: guesses} | _]) do
    case Enum.find(guesses, &(&1.guesser == name)) do
      nil -> @text_yellow
      _ -> @text_green
    end
  end

  defp name_color(name, :guess_the_tag, :pick, [%{guesses: guesses} | _]) do
    case Enum.find(guesses, &(name in &1.picked_by)) do
      nil -> @text_yellow
      _ -> @text_green
    end
  end

  defp name_color(_, _, _, _), do: @text_yellow
end
