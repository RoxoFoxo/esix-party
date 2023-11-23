defmodule Core.GameSetup do
  @moduledoc false

  alias Core.Games.GuessTheTag
  alias Core.Games.GuessTheTag.ImageSetup

  @game_types [GuessTheTag]

  def generate_into_games(posts) do
    games =
      posts
      |> Enum.map(&Map.put(&1, :image, ImageSetup.normal_to_memory(&1.image_binary)))
      |> Enum.map(&flatten_tags/1)
      |> Enum.map(&randomize_game_type/1)

    post_urls =
      games
      |> Enum.map(&Map.take(&1, [:image, :source]))

    {games, post_urls}
  end

  defp flatten_tags(%{tags: tags} = post) do
    %{post | tags: tags |> Map.values() |> List.flatten()}
  end

  # this will make more sense in the future, when there are more game types.
  defp randomize_game_type(post), do: Enum.random(@game_types).new(post)
end
