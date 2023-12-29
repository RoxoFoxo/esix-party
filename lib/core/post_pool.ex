defmodule Core.PostPool do
  use GenServer

  import Core.GameUtils

  alias Core.E621Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: :post_pool)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:get_posts, %{"amount_of_rounds" => amount_of_rounds} = params}, _from, state) do
    amount_of_rounds = String.to_integer(amount_of_rounds)

    pool_posts =
      state
      |> Enum.filter(&valid_post?(&1, params))
      |> Enum.take_random(amount_of_rounds)

    case length(pool_posts) do
      post_amount when post_amount == amount_of_rounds ->
        {:reply, pool_posts, state}

      post_amount ->
        tags_string = format_tags(params)

        new_posts = E621Client.get_random_posts(amount_of_rounds - post_amount, tags_string)

        {:reply, pool_posts ++ new_posts, state ++ new_posts}
    end
  end

  defp valid_post?(
         %{tags: tags, rating: post_rating},
         %{"blacklist" => blacklist_input} = params
       ) do
    post_tags = flatten_tags(tags)

    valid_tags? =
      blacklist_input
      |> String.split([" ", ","], trim: true)
      |> Enum.map(&(&1 not in post_tags))
      |> Enum.all?()

    valid_rating? =
      params
      |> Map.take(["safe?", "questionable?", "explicit?"])
      |> Enum.map(&check_rating(&1, :atom))
      |> Enum.member?(post_rating)

    valid_rating? && valid_tags?
  end

  defp format_tags(%{"blacklist" => blacklist_input} = params) do
    formatted_blacklist =
      blacklist_input
      |> String.split([" ", ","], trim: true)
      |> Enum.map(&("-" <> &1))

    ratings =
      params
      |> Map.take(["safe?", "questionable?", "explicit?"])
      |> Enum.map(&check_rating(&1, :tag))
      |> Enum.reject(&(&1 == false))

    Enum.join(formatted_blacklist ++ ratings, "+")
  end

  defp check_rating({_rating, "false"}, _), do: false

  defp check_rating({"safe?", "true"}, :atom), do: :safe
  defp check_rating({"questionable?", "true"}, :atom), do: :questionable
  defp check_rating({"explicit?", "true"}, :atom), do: :explicit

  defp check_rating({"safe?", "true"}, :tag), do: "~rating:s"
  defp check_rating({"questionable?", "true"}, :tag), do: "~rating:q"
  defp check_rating({"explicit?", "true"}, :tag), do: "~rating:e"
end
