defmodule Core.E621Client.API do
  @moduledoc false
  @behaviour Core.E621Client

  use Tesla

  require Logger

  plug(Tesla.Middleware.BaseUrl, "https://e621.net")
  plug(Tesla.Middleware.Headers, [{"user-agent", "guess-the-tag/1.0"}])
  plug(Tesla.Middleware.JSON)

  @default_tags ~w[ order:random -animated -gore -scat -watersports -young -loli -shota ]
                |> Enum.join("+")

  def get_random_posts(amount, tags) do
    url =
      "posts.json?limit=#{amount}&tags=score:>0+#{@default_tags}+#{tags}"
      |> URI.encode()

    with {:ok, result} <- get(url),
         posts <- result.body["posts"] do
      Logger.debug(inspect(posts, pretty: true))
      {:ok, posts}
    else
      error ->
        Logger.error(error)
        {:error, error}
    end
  end

  def get_img_binary(image_url) do
    {:ok, %{body: img_binary}} = image_url |> URI.encode() |> get()
    img_binary
  end
end
