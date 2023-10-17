defmodule CoreWeb.RoomLive do
  alias Core.RoomRegistry
  use CoreWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    Room name: <%= @name %>
    """
  end

  @impl true
  def mount(%{"name" => name}, _session, socket) do
    # later I'll use this line for broadcasts
    # if connected?(socket), do: IO.puts("connected lol")

    if RoomRegistry.exists?(name) do
      {:ok, assign(socket, :name, name)}
    else
      {:ok,
       socket
       |> put_flash(:error, "Room with code #{name} doesn't exist.")
       |> redirect(to: "/")}
    end
  end
end
