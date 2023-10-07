defmodule Core.E621Client do
  @moduledoc false

  alias Core.E621Client.API

  def get_random_posts(amount \\ 5, min_score \\ 200) do
    # amount and min_score will be defined at the games settings later, maybe?

    API.get_random_posts(amount, min_score)
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
