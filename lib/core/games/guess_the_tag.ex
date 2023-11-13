defmodule Core.Games.GuessTheTag do
  @moduledoc """
  Module to the Guess The Tag game type
  """

  defstruct [:image, :source, :tags, guesses: %{}, type: :guess_the_tag, censor: "placeholder"]

  def guess_changes([%{guesses: guesses, tags: game_tags} = game | tail], players, timer_ref) do
    updated_guesses = update_guesses(guesses, game_tags)

    updated_game =
      game
      |> Map.put(:guesses, updated_guesses)
      |> insert_esix_guess()

    Process.cancel_timer(timer_ref)

    %{
      game_status: :pick,
      games: [updated_game | tail],
      players: update_players(players, updated_guesses),
      timer_ref: Process.send_after(self(), :timer, 30000)
    }
  end

  defp update_guesses(guesses, game_tags) do
    all_guessed_tags =
      guesses
      |> Enum.map(fn {_, %{tags: tags}} -> tags end)
      |> List.flatten()

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
  end

  defp update_players(players, guesses) do
    for %{name: player_name, score: score} = player <- players do
      case guesses[player_name] do
        %{score: guess_score} -> %{player | score: score + guess_score}
        _ -> player
      end
    end
  end

  defp insert_esix_guess(%{tags: game_tags, guesses: guesses} = game) do
    esix_tags = Enum.take_random(game_tags, 5)

    %{game | guesses: Map.put(guesses, "eSix", %{tags: esix_tags, picked_by: [], score: 25})}
  end
end
