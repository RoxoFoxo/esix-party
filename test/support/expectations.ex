defmodule Core.Expectations do
  @moduledoc false

  import Mox

  alias Core.E621Mock

  @post_example %{
    "file" => %{"url" => "image_link.png"},
    "id" => 4_298_651,
    "tags" => %{
      "artist" => ["roxofoxo"],
      "characters" => ["roxo"],
      "copyright" => ["fennec_company"],
      "general" => ["purple_fur", "big_ears", "girly"],
      "lore" => ["agender"],
      "species" => ["fennec"],
      "meta" => ["omg_so_meta"],
      "invalid" => ["purple_idiot"]
    },
    "other_stuff" => "this shouldn't show up"
  }

  def expect_get_random_posts do
    E621Mock
    |> expect(:get_random_posts, fn _, _ ->
      {:ok,
       for _ <- 1..5 do
         @post_example
       end}
    end)
  end
end
