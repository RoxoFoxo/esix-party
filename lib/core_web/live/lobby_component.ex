defmodule CoreWeb.LobbyComponent do
  use CoreWeb, :live_component

  alias Core.E621Client
  alias Core.GameSetup

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p>Room name: <%= @state.name %></p>
      <p>Players:</p>
      <%= for player <- Enum.reverse(@state.players) do %>
        <%= player.name %> <br />
      <% end %>

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
          field={@form[:tags_to_blacklist]}
          type="text"
          placeholder="Global blacklist is always enabled. Separate tags using space."
          label="Blacklisted tags"
        />

        <.input field={@form[:safe?]} type="checkbox" label="Allow safe?" checked />
        <.input field={@form[:questionable?]} type="checkbox" label="Allow questionable?" />
        <.input field={@form[:explicit?]} type="checkbox" label="Allow explicit?" />

        <:actions>
          <.button phx-target={@myself}>START</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :form, to_form(%{}))}
  end

  @impl true
  def handle_event(
        "start",
        %{"amount_of_rounds" => amount_of_rounds},
        %{assigns: %{server_pid: server_pid, state: %{name: room_name}}} = socket
      ) do
    # TODO: add minimum score param here
    # TODO: add other params here aswell
    games =
      amount_of_rounds
      |> E621Client.get_random_posts()
      |> GameSetup.generate_into_games()

    new_status = get_new_status(games)

    GenServer.call(
      server_pid,
      {:update_state, room_name, %{games: games, status: new_status}}
    )

    {:noreply, socket}
  end

  defp get_new_status(games) do
    games
    |> Enum.at(0)
    |> then(& &1.game_type)
  end
end
