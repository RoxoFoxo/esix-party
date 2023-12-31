defmodule CoreWeb.LobbyComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p>Room name: <%= @state.name %></p>

      <%= if is_owner?(@current_player, @state.players) do %>
        <.simple_form for={@form} id="game_params" phx-target={@myself} phx-submit="start">
          <.input
            field={@form[:amount_of_rounds]}
            type="number"
            min="1"
            max="10"
            value="3"
            label="Amount of rounds"
          />

          <.input
            field={@form[:blacklist]}
            type="text"
            placeholder="Global blacklist is always enabled. Separate tags using space."
            label="Blacklisted tags"
          />

          <div class="flex gap-20 select-none">
            <.input field={@form[:safe?]} type="checkbox" label="Allow safe?" checked />
            <.input field={@form[:questionable?]} type="checkbox" label="Allow questionable?" />
            <.input field={@form[:explicit?]} type="checkbox" label="Allow explicit?" />
          </div>

          <:actions>
            <.button phx-target={@myself} phx-disable-with="Starting...">
              Start
            </.button>
          </:actions>
        </.simple_form>
      <% else %>
        <br />
        <p>Waiting for room owner to start the match.</p>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :form, to_form(%{}))}
  end

  @impl true
  def handle_event("start", params, %{assigns: %{server_pid: server_pid}} = socket) do
    GenServer.call(server_pid, {:game_setup, params}, 15000)
    {:noreply, socket}
  end
end
