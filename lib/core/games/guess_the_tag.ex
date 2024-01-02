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
    |> Map.put(:tampered_image, ImageSetup.tamper_to_memory(image_binary))
  end

  def guess_changes([%{guesses: guesses, tags: game_tags} = game | tail], players, timer_ref) do
    Process.cancel_timer(timer_ref)

    updated_guesses = guesses |> Enum.uniq_by(& &1.guesser) |> add_score_to_guesses(game_tags)

    updated_game =
      game
      |> Map.put(:guesses, updated_guesses)
      |> insert_esix_guess()
      |> shuffle_guesses()

    %{
      game_status: :pick,
      games: [updated_game | tail],
      players: award_guessers_for_guessing(players, updated_guesses)
    }
  end

  defp add_score_to_guesses(guesses, game_tags) do
    all_guessed_tags =
      guesses
      |> Enum.map(&Enum.uniq(&1.tags))
      |> List.flatten()

    for %{tags: guess_tags} = guess <- guesses do
      tag_tuples =
        guess_tags
        |> Enum.map(&String.downcase/1)
        |> Enum.map(fn tag -> {tag, tag in game_tags} end)
        |> Enum.reduce([], &add_tag_score(&1, &2, all_guessed_tags))

      guess_score =
        tag_tuples
        |> Enum.map(&elem(&1, 2))
        |> Enum.sum()

      %{guess | score: guess_score, tags: tag_tuples}
    end
  end

  def add_tag_score({tag, correct?}, acc_tags, all_guessed_tags) do
    with true <- correct?,
         false <- tag in Enum.map(acc_tags, fn {tag, _, _} -> tag end),
         tag_score <- 6 - Enum.count(all_guessed_tags, &(&1 == tag)),
         true <- tag_score >= 0 do
      {tag, true, tag_score}
    else
      _ -> {tag, correct?, 0}
    end
    |> then(&[&1 | acc_tags])
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
    esix_tags = game_tags |> Enum.take_random(5) |> Enum.map(&{&1, true, 5})

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
