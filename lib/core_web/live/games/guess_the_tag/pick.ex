defmodule CoreWeb.Games.GuessTheTag.PickComponent do
  use CoreWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= hd(@state.games).source %> <br /><br />

      <%= for {guesser, tags} <- hd(@state.games).guesses |> Enum.shuffle() do %>
        <.button
          phx-click="pick"
          phx-target={@myself}
          phx-value-guesser={guesser}
          style="width: 200px; text-align: left"
        >
          <%= for tag <- Enum.shuffle(tags) do %>
            <%= tag %> <br />
          <% end %>
        </.button>
        <hr />
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event(
        "pick",
        %{"guesser" => guesser},
        %{assigns: %{current_player: current_player}} = socket
      ) do
    guesser
    |> IO.inspect(label: "guesser")

    {:noreply, socket}
  end
end
