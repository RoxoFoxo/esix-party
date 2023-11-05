defmodule CoreWeb.Games.GuessTheTag.PickComponent do
  use CoreWeb, :live_component

  @disabled_attribute [{"disabled", ""}]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= for {guesser, %{tags: tags}} <- hd(@state.games).guesses |> Enum.shuffle() do %>
        <.button
          phx-click="pick"
          phx-target={@myself}
          phx-value-guesser={guesser}
          style="width: 200px; text-align: left"
          {disable_if_guesser(@current_player, guesser)}
          {disable_if_already_picked(@current_player, hd(@state.games).guesses)}
        >
          <%= for tag <- Enum.shuffle(tags) do %>
            <%= tag %> <br />
          <% end %>
        </.button>
        <hr />
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event(
        "pick",
        %{"guesser" => guesser},
        %{
          assigns: %{
            server_pid: server_pid,
            current_player: current_player,
            state: %{
              games: [%{guesses: guesses} = game | tail],
              players: players
            }
          }
        } = socket
      ) do
    guess = %{picked_by: picked_by} = guesses[guesser]
    new_picked_by = [current_player | picked_by]

    updated_game =
      guess
      |> Map.put(:picked_by, new_picked_by)
      |> then(&Map.put(guesses, guesser, &1))
      |> then(&Map.put(game, :guesses, &1))
      |> IO.inspect(label: "WHAT NOW")

    changes =
      if all_players_picked?(players, updated_game) do
        %{games: [updated_game | tail], game_status: :results}
      else
        %{games: [updated_game | tail]}
      end

    GenServer.call(
      server_pid,
      {:update_state, changes}
    )

    {:noreply, socket}
  end

  defp all_players_picked?(players, %{guesses: guesses}) do
    pickers =
      Enum.reduce(guesses, [], fn {_, %{picked_by: picked_by}}, acc -> picked_by ++ acc end)

    players
    |> Enum.map(fn %{name: player} -> player in pickers end)
    |> Enum.all?()
    |> IO.inspect(label: "FUCk")
  end

  def disable_if_guesser(player, guesser) when player == guesser, do: @disabled_attribute
  def disable_if_guesser(_, _), do: []

  def disable_if_already_picked(player, guesses) do
    already_picked? =
      guesses
      |> Enum.flat_map(fn {_, %{picked_by: picked_by}} -> picked_by end)
      |> Enum.member?(player)

    if already_picked?, do: @disabled_attribute, else: []
  end
end
