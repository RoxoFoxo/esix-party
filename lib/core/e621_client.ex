defmodule Core.E621Client do
  @moduledoc false
  @callback get_random_posts(integer(), integer()) :: {:ok, list()}

  # amount and min_score will be defined at the games settings later, maybe?
  def get_random_posts(amount \\ 5, min_score \\ 200) do
    adapter = Application.get_env(:e621, :api, Core.E621Client.API)

    adapter.get_random_posts(amount, min_score)
    |> then(fn {:ok, posts} -> posts end)
    |> Enum.map(&get_post_info/1)
  end

  defp get_post_info(post) do
    tags = remove_bad_tags(post["tags"])

    {
      post["file"]["url"],
      post["id"],
      tags
    }
  end

  defp remove_bad_tags(tags) do
    tags
    |> Map.drop(["meta", "invalid"])
  end
end
