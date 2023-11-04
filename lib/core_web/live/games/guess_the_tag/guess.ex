defmodule CoreWeb.Games.GuessTheTag.GuessComponent do
  use CoreWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <img src={hd(@state.games).image} style="filter: blur(20px)" />
      <%= hd(@state.games).source %>

      <.simple_form for={@form} id="guess_input" phx-target={@myself} phx-submit="guess_submit">
        <.input
          id="tag_input"
          field={@form[:guess]}
          type="text"
          label="Guess five tags from this image!"
          autocomplete="off"
        />

        <:actions>
          <.button phx-target={@myself}>Submit</.button>
        </:actions>

        <%= @fail_msg %>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:fail_msg, nil)
     |> assign(:form, to_form(%{}))}
  end

  @impl true
  def handle_event(
        "guess_submit",
        %{"guess" => guess},
        %{
          assigns: %{
            server_pid: server_pid,
            current_player: current_player,
            state: %{name: name, games: [game | tail]}
          }
        } = socket
      ) do
    case validate_guess(guess) do
      :invalid ->
        {:noreply, assign(socket, :fail_msg, "It needs to be five tags!")}

      guess_tags ->
        updated_game = put_in(game.guesses, Map.put(game.guesses, current_player, guess_tags))

        GenServer.call(
          server_pid,
          {:update_state, name, %{games: [updated_game | tail]}}
        )

        # JS.set_attribute({"readonly", ""}, to: "#tag_input")

        {:noreply, socket}
    end
  end

  defp validate_guess(guess) do
    guess_tags = String.split(guess, [" ", ","], trim: true)

    case length(guess_tags) do
      5 -> guess_tags
      _ -> :invalid
    end
  end
end
