defmodule Core.E621Client.API do
  @moduledoc false

  use Tesla

  require Logger

  plug(Tesla.Middleware.BaseUrl, "https://e621.net")
  plug(Tesla.Middleware.Headers, [{"user-agent", "guess-the-tag/1.0"}])
  plug(Tesla.Middleware.JSON)

  @default_tags ~w[ order:random -animated -gore -scat -watersports -young -loli -shota ]
                |> Enum.join("+")

  def get_random_posts(amount, min_score) do
    url =
      "posts.json?limit=#{amount}&tags=score:>#{min_score}+#{@default_tags}"
      |> URI.encode()

    with {:ok, result} <- get(url),
         posts <- result.body["posts"] do
      Logger.debug(inspect(posts, pretty: true))

      posts
    else
      error -> error
    end
  end
end
