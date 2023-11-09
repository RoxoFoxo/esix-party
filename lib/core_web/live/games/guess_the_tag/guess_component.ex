defmodule CoreWeb.Games.GuessTheTag.GuessComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

  @disabled_attribute [{"disabled", ""}]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} id="guess_input" phx-target={@myself} phx-submit="guess_submit">
        <.input
          id="tag_input"
          field={@form[:guess]}
          type="text"
          label="Guess five tags from this image!"
          autocomplete="off"
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
            state: %{games: [%{tags: game_tags} = game | tail], players: players}
          }
        } = socket
      ) do
    case validate_guess(guess) do
      :invalid ->
        {:noreply, assign(socket, :fail_msg, "It needs to be five tags!")}

      tags ->
        updated_game = insert_guess(game, tags, current_player)

        changes =
          if all_players_guessed?(players, updated_game.guesses) do
            {updated_guesses, updated_players} = award_guesses(players, updated_game)

            esix_tags = Enum.take_random(game_tags, 5)

            updated_game =
              updated_game
              |> Map.put(:guesses, updated_guesses)
              |> insert_guess(esix_tags, "eSix")

            %{
              games: [updated_game | tail],
              players: updated_players,
              game_status: :pick
            }
          else
            %{games: [updated_game | tail]}
          end

        update_state(socket, server_pid, changes)
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
    score = if player_name == "eSix", do: 25

    updated_guesses = Map.put(guesses, player_name, %{tags: tags, picked_by: [], score: score})
    %{game | guesses: updated_guesses}
  end

  defp award_guesses(players, %{guesses: guesses, tags: game_tags}) do
    all_guessed_tags =
      guesses
      |> Enum.map(fn {_, %{tags: tags}} -> tags end)
      |> List.flatten()

    updated_guesses =
      for {guesser, %{tags: tags} = guess} <- guesses do
        guess_score =
          tags
          |> Enum.uniq()
          |> Enum.filter(&(&1 in game_tags))
          |> Enum.map(&String.downcase/1)
          |> Enum.map(fn tag -> Enum.count(all_guessed_tags, &(&1 == tag)) end)
          |> Enum.map(&(6 - &1))
          |> Enum.reject(&(&1 < 0))
          |> Enum.sum()

        {guesser, %{guess | score: guess_score}}
      end
      |> Map.new()

    updated_players =
      for %{name: player_name, score: score} = player <- players do
        case updated_guesses[player_name] do
          %{score: guess_score} -> %{player | score: score + guess_score}
          _ -> player
        end
      end

    {updated_guesses, updated_players}
  end

  defp all_players_guessed?(players, guesses) do
    player_names = Enum.map(players, & &1.name)
    guessers = Map.keys(guesses)

    Enum.all?(player_names, &(&1 in guessers))
  end

  defp disable_if_guessed(current_player, guesses) do
    if current_player in Map.keys(guesses), do: @disabled_attribute, else: []
  end
end
