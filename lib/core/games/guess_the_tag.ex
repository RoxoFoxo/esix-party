defmodule Core.Games.GuessTheTag do
  @moduledoc """
  Module to the Guess The Tag game type
  """

  defstruct [:image, :source, :tags, guesses: %{}, type: :guess_the_tag, censor: "placeholder"]

  def guess_changes([%{guesses: guesses, tags: game_tags} = game | tail], players, timer_ref) do
    Process.cancel_timer(timer_ref)

    updated_guesses = add_score_to_guesses(guesses, game_tags)

    updated_game =
      game
      |> Map.put(:guesses, updated_guesses)
      |> insert_esix_guess()

    %{
      game_status: :pick,
      games: [updated_game | tail],
      players: award_guessers_for_guessing(players, updated_guesses),
      timer_ref: Process.send_after(self(), :timer, 30000)
    }
  end

  defp add_score_to_guesses(guesses, game_tags) do
    all_guessed_tags =
      guesses
      |> Enum.map(fn {_, %{tags: tags}} -> tags end)
      |> List.flatten()

    for {guesser, %{tags: tags} = guess} <- guesses do
      guess_score =
        tags
        |> Enum.map(&String.downcase/1)
        |> Enum.uniq()
        |> Enum.filter(&(&1 in game_tags))
        |> Enum.map(fn tag -> Enum.count(all_guessed_tags, &(&1 == tag)) end)
        |> Enum.map(&(6 - &1))
        |> Enum.reject(&(&1 < 0))
        |> Enum.sum()

      {guesser, %{guess | score: guess_score}}
    end
    |> Map.new()
  end

  defp award_guessers_for_guessing(players, guesses) do
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

  def pick_changes([%{guesses: guesses} = game | tail], players, timer_ref) do
    Process.cancel_timer(timer_ref)

    updated_players = players |> award_pickers(guesses) |> award_guessers(guesses)

    %{
      games: [game | tail],
      players: updated_players,
      game_status: :results,
      timer_ref: nil
    }
  end

  defp award_pickers(players, guesses) do
    for %{name: player_name, score: player_score} = player <- players do
      guess = Enum.find(guesses, fn {_, %{picked_by: picked_by}} -> player_name in picked_by end)

      case guess do
        {_, %{score: guess_score}} -> %{player | score: player_score + div(guess_score, 2)}
        _ -> player
      end
    end
  end

  defp award_guessers(players, guesses) do
    for {guesser, %{picked_by: picked_by}} <- guesses do
      case guesser do
        "eSix" ->
          :esix

        _ ->
          %{score: player_score} = player = Enum.find(players, &(&1.name == guesser))

          pick_score = Enum.reduce(picked_by, 0, fn _, acc -> acc + 5 end)

          %{player | score: player_score + pick_score}
      end
    end
    |> Enum.reject(&(&1 == :esix))
  end
end
