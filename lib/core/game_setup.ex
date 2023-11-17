defmodule Core.GameSetup do
  @moduledoc false

  alias Core.Games.GuessTheTag

  @game_types [GuessTheTag]
  # TODO: create and add censors
  # @censors ["placeholder"]

  def generate_into_games(posts) do
    games =
      posts
      |> Enum.map(&flatten_tags/1)
      |> Enum.map(&randomize_game_type/1)

    post_urls = Enum.map(posts, &Map.drop(&1, [:tags, :image_binary]))

    {games, post_urls}
  end

  defp flatten_tags(%{tags: tags} = post) do
    %{post | tags: tags |> Map.values() |> List.flatten()}
  end

  # this will make more sense in the future, when there are more game types.
  defp randomize_game_type(post), do: Enum.random(@game_types).new(post)
end
