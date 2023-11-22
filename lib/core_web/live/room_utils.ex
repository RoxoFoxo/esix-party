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
             server_pid: server_pid,
             current_player: current_player,
             state: %{
               players: players,
               timer_ref: timer_ref
             }
           }
         } = socket
       ) do
    with true <- Enum.find_value(players, &if(&1.name == current_player, do: &1.owner?)),
         false <- timer_ref != nil and Process.read_timer(timer_ref) do
      GenServer.cast(server_pid, :start_timer)
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
