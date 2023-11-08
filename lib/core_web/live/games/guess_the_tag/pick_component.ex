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

    changes =
      if all_players_picked?(players, updated_game) do
        updated_players = players |> award_pickers(updated_game) |> award_guessers(updated_game)

        %{games: [updated_game | tail], players: updated_players, game_status: :results}
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
  end

  defp award_pickers(players, %{guesses: guesses}) do
    for %{name: player_name, score: player_score} = player <- players do
      guess = Enum.find(guesses, fn {_, %{picked_by: picked_by}} -> player_name in picked_by end)

      case guess do
        {_, %{score: guess_score}} -> %{player | score: player_score + guess_score}
        _ -> player
      end
    end
  end

  defp award_guessers(players, %{guesses: guesses}) do
    for {guesser, %{picked_by: picked_by}} <- guesses do
      case guesser do
        "eSix" ->
          :esix

        _ ->
          %{score: player_score} = player = Enum.find(players, &(&1.name == guesser))

          pick_score =
            picked_by
            |> length()
            |> then(&(&1 * 5))

          %{player | score: player_score + pick_score}
      end
    end
    |> Enum.reject(&(&1 == :esix))
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
