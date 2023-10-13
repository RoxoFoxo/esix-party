defmodule CoreWeb.PageController do
  use CoreWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:posts, Core.E621Client.get_random_posts())
    |> render(:home)
  end
end
