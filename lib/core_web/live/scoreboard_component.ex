defmodule CoreWeb.ScoreboardComponent do
  use CoreWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p class="text-center">
        <%= if @status == :lobby, do: "Players", else: "Scoreboard" %>
      </p>
      <div class="flex flex-col">
        <%= for %{name: name, owner?: owner?, score: score} <- order_by_score(@players) do %>
          <div class="flex flex-row gap-x-2 justify-between">
            <div>
              <span class="text-yellow-500"><%= name %></span>
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

  defp order_by_score(players) do
    if Enum.any?(players, &(&1.score != 0)) do
      Enum.sort_by(players, & &1.score, :desc)
    else
      Enum.reverse(players)
    end
  end
end
