defmodule CoreWeb.LobbyComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

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
          field={@form[:blacklist]}
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
        %{
          "amount_of_rounds" => amount_of_rounds,
          "blacklist" => blacklist
        } = params,
        %{assigns: %{server_pid: server_pid}} = socket
      ) do
    formatted_blacklist =
      blacklist
      |> String.split(" ", trim: true)
      |> Enum.map(&("-" <> &1))

    ratings =
      params
      |> Map.take(["safe?", "questionable?", "explicit?"])
      |> Enum.map(&check_rating/1)
      |> Enum.reject(&(&1 == ""))

    tags =
      (formatted_blacklist ++ ratings)
      |> Enum.join("+")

    {games, post_urls} =
      amount_of_rounds
      |> E621Client.get_random_posts(tags)
      |> GameSetup.generate_into_games()

    changes = %{
      games: games,
      post_urls: post_urls,
      status: get_new_status(games),
      blacklist: blacklist
    }

    update_state(socket, server_pid, changes)
  end

  def check_rating({_rating, "false"}), do: ""

  def check_rating({rating, "true"}) do
    case rating do
      "safe?" -> "~rating:s"
      "questionable?" -> "~rating:q"
      "explicit?" -> "~rating:e"
    end
  end

  defp get_new_status(games) do
    games
    |> Enum.at(0)
    |> then(& &1.game_type)
  end
end
