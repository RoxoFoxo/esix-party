defmodule CoreWeb.HomeLive do
  use CoreWeb, :live_view

  alias Core.Room

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl grid gap-4 mx-auto bg-blue-950 rounded-xl border-2 border-indigo-950 px-8 pb-8">
      <div>
        <.simple_form for={@form} id="join-room" phx-submit="join_room">
          <.input field={@form[:room_name]} type="text" label="Room Name" autocomplete="off" />
          <:actions>
            <.button>Join room</.button>
          </:actions>
        </.simple_form>
      </div>

      <div>
        <.button phx-click="new_room">Create a new room</.button>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form, to_form(%{}))}
  end

  @impl true
  def handle_event("new_room", _unsigned_params, socket) do
    room_name = new_room()

    {:noreply, redirect(socket, to: "/room/" <> room_name)}
  end

  def handle_event("join_room", %{"room_name" => room_name}, socket) do
    room_name = String.upcase(room_name)

    {:noreply, redirect(socket, to: "/room/" <> room_name)}
  end

  defp new_room do
    {:ok, pid} = Room.new()

    GenServer.call(pid, :get_name)
  end
end
