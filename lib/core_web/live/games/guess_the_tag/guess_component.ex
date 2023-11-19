defmodule CoreWeb.Games.GuessTheTag.GuessComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

  alias Core.Games.GuessTheTag
  alias Core.Games.GuessTheTag.Guess

  @disabled_attribute [{"disabled", ""}]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} id="guess_input" phx-target={@myself} phx-submit="guess_submit">
        <.input
          id="tag_input"
          field={@form[:guess_tags]}
          type="text"
          label="Guess five tags from this image!"
          autocomplete="off"
          autofocus
          {disable_if_guessed(@current_player, hd(@state.games).guesses)}
        />

        <:actions>
          <.button {disable_if_guessed(@current_player, hd(@state.games).guesses)}>
            Submit
          </.button>
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
     |> assign(:form, to_form(%{}))
     |> attach_timer_hook()}
  end

  @impl true
  def handle_event(
        "guess_submit",
        %{"guess_tags" => guess_tags},
        %{
          assigns: %{
            current_player: current_player,
            state: %{games: [game | tail], players: players, timer_ref: timer_ref}
          }
        } = socket
      ) do
    case validate_guess(guess_tags) do
      :invalid ->
        {:noreply, assign(socket, :fail_msg, "It needs to be five tags!")}

      tags ->
        updated_game = insert_guess(game, tags, current_player)

        changes =
          if all_players_guessed?(players, updated_game.guesses) do
            GuessTheTag.guess_changes([updated_game | tail], players, timer_ref)
          else
            %{games: [updated_game | tail]}
          end

        {:noreply, update_state(socket, changes)}
    end
  end

  defp validate_guess(guess) do
    tags = String.split(guess, [" ", ","], trim: true)

    case length(tags) do
      5 -> tags
      _ -> :invalid
    end
  end

  defp insert_guess(%{guesses: guesses} = game, tags, player_name) do
    %{game | guesses: [%Guess{guesser: player_name, tags: tags} | guesses]}
  end

  defp all_players_guessed?(players, guesses) do
    player_names = Enum.map(players, & &1.name)
    guessers = Enum.map(guesses, & &1.guesser)

    Enum.all?(player_names, &(&1 in guessers))
  end

  defp disable_if_guessed(current_player, guesses) do
    if current_player in Enum.map(guesses, & &1.guesser), do: @disabled_attribute, else: []
  end
end
