defmodule CoreWeb.RoomUtils do
  @inactive_msg "Sorry, but this room has timed out for inactivity, please create a new one."

  alias Phoenix.LiveView

  def update_state(%{assigns: %{server_pid: server_pid}} = socket, changes) do
    if Process.alive?(server_pid) do
      GenServer.call(server_pid, {:update_state, changes})

      socket
    else
      redirect_to_home(socket, {:error, @inactive_msg})
    end
  end

  def redirect_to_home(socket, {kind, msg}) do
    socket
    |> LiveView.put_flash(kind, msg)
    |> LiveView.redirect(to: "/")
  end

  def attach_timer_hook(socket) do
    LiveView.attach_hook(socket, :start_timer, :after_render, &start_timer_hook/1)
  end

  defp start_timer_hook(
         %{
           assigns: %{
             current_player: current_player,
             state: %{
               players: players,
               status: status,
               game_status: game_status,
               timer_ref: timer_ref
             }
           }
         } = socket
       ) do
    with true <- Enum.find_value(players, &if(&1.name == current_player, do: &1.owner?)),
         false <- timer_ref != nil and Process.read_timer(timer_ref) do
      time =
        case {status, game_status} do
          {:guess_the_tag, :pick} -> 30000
          {:guess_the_tag, _} -> 60000
        end

      send(self(), {:start_timer, time})
    end

    Process.send_after(self(), :tick, 1000)

    socket |> LiveView.detach_hook(:start_timer, :after_render)
  end

  def hide_if_not_owner(nil, _players), do: [{"hidden", ""}]

  def hide_if_not_owner(current_player, players) do
    case is_owner?(current_player, players) do
      true -> []
      false -> [{"hidden", ""}]
    end
  end

  def is_owner?(current_player, players) do
    case Enum.find(players, &(&1.name == current_player)) do
      %{owner?: owner?} -> owner?
      _ -> false
    end
  end
end
