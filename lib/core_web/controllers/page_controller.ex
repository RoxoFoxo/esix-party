defmodule CoreWeb.PageController do
  use CoreWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> assign(:posts, Core.E621Client.get_random_posts())
    |> render(:home, layout: false)
  end
end
