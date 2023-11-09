defmodule CoreWeb.Games.GuessTheTagComponent do
  use CoreWeb, :live_component

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
      <img
        src={hd(@state.games).image}
        style={if @state.game_status != :results, do: "filter: blur(20px)", else: ""}
      />
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
  def update(
        %{
          server_pid: server_pid,
          state: %{game_status: game_status}
        } = assigns,
        socket
      ) do
    unless game_status do
      GenServer.call(server_pid, {:update_state, %{game_status: :guess}})
    end

    {:ok, assign(socket, assigns)}
  end

  def fetch_component(nil), do: @components[:guess]
  def fetch_component(game_status), do: @components[game_status]
end
