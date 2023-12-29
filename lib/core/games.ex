defmodule Core.Games do
  @moduledoc false

  import Core.GameUtils

  alias Core.Games.GuessTheTag
  alias Core.Games.GuessTheTag.ImageSetup

  @game_types [GuessTheTag]

  def setup(params) do
    posts = GenServer.call(:post_pool, {:get_posts, params})

    games =
      posts
      |> Enum.map(&Map.put(&1, :image, ImageSetup.normal_to_memory(&1.image_binary)))
      |> Enum.map(&Map.put(&1, :tags, flatten_tags(&1.tags)))
      |> Enum.map(&Map.delete(&1, :rating))
      |> Enum.map(&randomize_game_type/1)

    post_urls =
      games
      |> Enum.map(&Map.take(&1, [:image, :source]))

    {games, post_urls}
  end

  # this will make more sense in the future, when there are more game types.
  defp randomize_game_type(post), do: Enum.random(@game_types).new(post)
end
