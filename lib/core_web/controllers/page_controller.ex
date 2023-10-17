defmodule CoreWeb.PageController do
  use CoreWeb, :controller

  alias Core.GameRoom

  def home(conn, _params) do
    conn
    |> assign(:posts, Core.E621Client.get_random_posts())
    |> render(:home)
  end

  def new_room do
    {:ok, pid} = GameRoom.new()

    GenServer.call(pid, :get_name)
    |> then(&("/room/" <> &1))
  end
end
