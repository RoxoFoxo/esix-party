defmodule CoreWeb.GuessTheTagComponent do
  use CoreWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <img src={Enum.at(@state.games, @state.game_index).image} />
      <%= Enum.at(@state.games, @state.game_index).source %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
