defmodule CoreWeb.Games.GuessTheTagComponent do
  use CoreWeb, :live_component

  @components %{
    guess: CoreWeb.Games.GuessTheTag.GuessComponent
  }

  @impl true
  def render(assigns) do
    ~H"""
    <div>
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
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    GenServer.call(
      assigns.server_pid,
      {:update_state, assigns.state.name, %{game_status: :guess}}
    )

    assigns = Map.put(assigns, :game_status, :guess)

    {:ok, assign(socket, assigns)}
  end

  def fetch_component(game_status), do: @components[game_status]
end
