defmodule Core.E621Client do
  @moduledoc false
  @callback get_random_posts(integer(), String.t(), String.t()) ::
              {:ok, list()} | {:error, term()}

  def get_random_posts(amount, tags) do
    adapter = Application.get_env(:e621, :api, Core.E621Client.API)

    adapter.get_random_posts(amount, tags)
    |> then(fn {:ok, posts} -> posts end)
    |> Enum.map(&get_post_info/1)
  end

  defp get_post_info(post) do
    tags = remove_bad_tags(post["tags"])

    %{
      image: post["file"]["url"],
      source: "https://e621.net/posts/#{post["id"]}",
      tags: tags
    }
  end

  defp remove_bad_tags(tags) do
    tags
    |> Map.drop(["meta", "invalid"])
  end
end
