defmodule CoreWeb.Games.GuessTheTag.PickComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

  alias Core.Games.GuessTheTag

  @disabled_attribute [{"disabled", ""}]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= for %{guesser: guesser, tags: tags} <- hd(@state.games).guesses do %>
        <.button
          phx-click="pick"
          phx-target={@myself}
          phx-value-guesser={guesser}
          style="width: 200px; text-align: left"
          {disable_if_guesser(@current_player, guesser)}
          {disable_if_already_picked(@current_player, hd(@state.games).guesses)}
        >
          <%= for tag <- tags do %>
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
              players: players,
              timer_ref: timer_ref
            }
          }
        } = socket
      ) do
    updated_guesses =
      Enum.map(guesses, fn
        %{guesser: ^guesser, picked_by: picked_by} = guess ->
          %{guess | picked_by: [current_player | picked_by]}

        guess ->
          guess
      end)

    updated_game = Map.put(game, :guesses, updated_guesses)

    changes =
      if all_players_picked?(players, updated_game) do
        GuessTheTag.pick_changes([updated_game | tail], players, timer_ref)
      else
        %{games: [updated_game | tail]}
      end

    update_state(socket, server_pid, changes)
  end

  defp all_players_picked?(players, %{guesses: guesses}) do
    pickers =
      Enum.reduce(guesses, [], fn %{picked_by: picked_by}, acc -> picked_by ++ acc end)

    players
    |> Enum.map(fn %{name: player} -> player in pickers end)
    |> Enum.all?()
  end

  def disable_if_guesser(player, guesser) when player == guesser, do: @disabled_attribute
  def disable_if_guesser(_, _), do: []

  def disable_if_already_picked(player, guesses) do
    already_picked? =
      guesses
      |> Enum.flat_map(& &1.picked_by)
      |> Enum.member?(player)

    if already_picked?, do: @disabled_attribute, else: []
  end
end
