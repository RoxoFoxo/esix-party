defmodule CoreWeb.ScoreboardComponent do
  use CoreWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p>Players:</p>
      <%= for player <- order_by_score(@players) do %>
        <p>
          <span class="text-yellow-500"><%= player.name %></span> <%= if @status != :lobby,
            do: player.score %>
        </p>
      <% end %>
    </div>
    """
  end

  defp order_by_score(players), do: Enum.sort_by(players, & &1.score, :desc)
end
