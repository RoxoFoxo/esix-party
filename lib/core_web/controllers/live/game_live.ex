defmodule CoreWeb.GameLive do
  use CoreWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    haha lol?: <%= @page %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # if connected?(socket), do: IO.puts("connected lol")

    {:ok, assign(socket, :page, "lol")}
    # |> IO.inspect()
  end
end
