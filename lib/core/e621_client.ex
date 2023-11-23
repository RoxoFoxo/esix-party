defmodule Core.E621Client do
  @moduledoc false
  @callback get_random_posts(integer(), String.t()) ::
              {:ok, list()} | {:error, term()}

  def get_random_posts(amount, tags) do
    adapter = Application.get_env(:e621, :api, Core.E621Client.API)

    adapter.get_random_posts(amount, tags)
    |> then(fn {:ok, posts} -> posts end)
    |> Enum.map(&get_post_info(&1, adapter))
  end

  defp get_post_info(%{"file" => %{"url" => image}, "tags" => tags, "id" => id}, adapter) do
    %{
      image_binary: adapter.get_img_binary(image),
      source: "https://e621.net/posts/#{id}",
      tags: remove_bad_tags(tags)
    }
  end

  defp remove_bad_tags(%{"artist" => artist_tags} = tags) do
    tags
    |> Map.drop(["meta", "invalid"])
    |> Map.put("artist", Enum.reject(artist_tags, &(&1 == "conditional_dnp")))
  end
end
