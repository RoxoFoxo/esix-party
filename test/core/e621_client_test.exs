defmodule Core.E621ClientTest do
  use Core.DataCase

  alias Core.E621Client
  alias Core.Expectations

  @expected_tags %{
    "artist" => ["roxofoxo"],
    "characters" => ["roxo"],
    "copyright" => ["fennec_company"],
    "general" => ["purple_fur", "big_ears", "girly"],
    "lore" => ["agender"],
    "species" => ["fennec"]
  }

  describe "get_random_posts" do
    test "gets image, id and only the correct tags from five posts" do
      Expectations.expect_get_random_posts()

      assert post_infos = E621Client.get_random_posts()
      assert length(post_infos) == 5

      for post_info <- post_infos do
        assert post_info.image == "image_link.png"
        assert post_info.source == "https://e621.net/posts/4298651"
        assert post_info.tags == @expected_tags
      end
    end
  end
end
