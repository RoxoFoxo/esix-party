defmodule CoreWeb.Games.GuessTheTagComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

  alias CoreWeb.Games.GuessTheTag

  @components %{
    guess: GuessTheTag.GuessComponent,
    pick: GuessTheTag.PickComponent,
    results: GuessTheTag.ResultsComponent
  }

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @state.game_status != :results do %>
        <img src={"data:image/jpeg;base64," <> hd(@state.games).tampered_image} />
        <br />Time remaining: <%= @time_remaining %>
      <% else %>
        <img src={hd(@state.games).image} />
      <% end %>

      <br />

      <.live_component
        module={fetch_component(@state.game_status)}
        id="guess_the_tag_component"
        state={@state}
        server_pid={@server_pid}
        current_player={@current_player}
      />
    </div>
    """
  end

  @impl true
  def update(%{state: %{game_status: game_status}} = assigns, socket) do
    if game_status do
      {:ok, assign(socket, assigns)}
    else
      {:ok,
       socket
       |> assign(assigns)
       |> update_state(%{game_status: :guess})}
    end
  end

  def fetch_component(nil), do: @components[:guess]
  def fetch_component(game_status), do: @components[game_status]
end
