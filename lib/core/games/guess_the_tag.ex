defmodule Core.Games.GuessTheTag do
  @moduledoc """
  Module to the Guess The Tag game type
  """

  alias Core.Games.GuessTheTag.Guess
  alias Core.Games.GuessTheTag.ImageSetup

  defstruct [
    :image,
    :tampered_image,
    :source,
    :tags,
    guesses: [],
    type: :guess_the_tag
  ]

  def new(%{image_binary: image_binary} = post) do
    __MODULE__
    |> struct(post)
    |> Map.put(:tampered_image, ImageSetup.edit(image_binary))
  end

  def guess_changes([%{guesses: guesses, tags: game_tags} = game | tail], players, timer_ref) do
    Process.cancel_timer(timer_ref)

    updated_guesses = add_score_to_guesses(guesses, game_tags)

    updated_game =
      game
      |> Map.put(:guesses, updated_guesses)
      |> insert_esix_guess()
      |> shuffle_guesses()

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
      |> Enum.map(fn %{tags: tags} -> tags end)
      |> List.flatten()

    for %{tags: tags} = guess <- guesses do
      guess_score =
        tags
        |> Enum.map(&String.downcase/1)
        |> Enum.uniq()
        |> Enum.filter(&(&1 in game_tags))
        |> Enum.map(fn tag -> Enum.count(all_guessed_tags, &(&1 == tag)) end)
        |> Enum.map(&(6 - &1))
        |> Enum.reject(&(&1 < 0))
        |> Enum.sum()

      %{guess | score: guess_score}
    end
  end

  defp award_guessers_for_guessing(players, guesses) do
    for %{name: player_name, score: score} = player <- players do
      case Enum.find(guesses, &(&1.guesser == player_name)) do
        %{score: guess_score} -> %{player | score: score + guess_score}
        _ -> player
      end
    end
  end

  defp insert_esix_guess(%{tags: game_tags, guesses: guesses} = game) do
    esix_tags = Enum.take_random(game_tags, 5)

    %{
      game
      | guesses: [%Guess{guesser: "eSix", tags: esix_tags, picked_by: [], score: 25} | guesses]
    }
  end

  defp shuffle_guesses(%{guesses: guesses} = game) do
    guesses
    |> Enum.map(fn %{tags: tags} = guess -> %{guess | tags: Enum.shuffle(tags)} end)
    |> Enum.shuffle()
    |> then(&%{game | guesses: &1})
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
      guess = Enum.find(guesses, fn %{picked_by: picked_by} -> player_name in picked_by end)

      case guess do
        %{score: guess_score} -> %{player | score: player_score + div(guess_score, 2)}
        _ -> player
      end
    end
  end

  defp award_guessers(players, guesses) do
    for %{name: player_name, score: player_score} = player <- players do
      case Enum.find(guesses, &(&1.guesser == player_name)) do
        %{picked_by: picked_by} ->
          pick_score = Enum.reduce(picked_by, 0, fn _, acc -> acc + 5 end)
          %{player | score: player_score + pick_score}

        nil ->
          player
      end
    end
  end
end
