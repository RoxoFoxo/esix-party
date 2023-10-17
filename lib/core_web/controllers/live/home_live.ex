defmodule CoreWeb.HomeLive do
  use CoreWeb, :live_view

  alias Core.GameRoom

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <button phx-click="new_room">NEW ROOM</button>

    </div>
    """

    # <%= for post <- @posts do %>
    #   <img src={post.image} style="width:200px" />
    #   <a href={post.source} class="button">Image source</a>
    # <% end %>
  end

  def new_room do
    {:ok, pid} = GameRoom.new()

    GenServer.call(pid, :get_name)
    |> then(&("/room/" <> &1))
  end

  @impl true
  def mount(_params, _session, socket) do
    # {:ok, assign(socket, :posts, Core.E621Client.get_random_posts())}
    {:ok, socket}
  end

  @impl true
  def handle_event("new_room", _unsigned_params, socket) do
    {:noreply, redirect(socket, to: new_room())}
  end
end
