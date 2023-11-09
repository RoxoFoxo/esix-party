defmodule Core.GameSetup do
  @game_types ~w[ guess_the_tag ]a
  # TODO: create and add censors
  @censors ["placeholder"]

  def generate_into_games(posts) do
    games =
      posts
      |> Enum.map(&flatten_tags/1)
      |> Enum.map(&randomize_game_type/1)
      |> Enum.map(&add_game_type_keys/1)

    post_urls =
      posts
      |> Enum.map(&Map.delete(&1, :tags))

    {games, post_urls}
  end

  defp flatten_tags(%{tags: tags} = post) do
    %{post | tags: tags |> Map.values() |> List.flatten()}
  end

  # this will make more sense in the future, when there are more game types.
  defp randomize_game_type(post) do
    Map.put(post, :game_type, Enum.random(@game_types))
  end

  defp add_game_type_keys(post) when post.game_type == :guess_the_tag do
    %{
      censor: Enum.random(@censors),
      guesses: %{}
    }
    |> Map.merge(post)
  end
end
