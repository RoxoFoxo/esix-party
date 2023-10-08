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

      for {image, id, tags} <- post_infos do
        assert image == "image_link.png"
        assert id == 4_298_651
        assert tags == @expected_tags
      end
    end
  end
end
