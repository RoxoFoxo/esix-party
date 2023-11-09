defmodule CoreWeb.RoomUtils do
  @inactive_msg "Sorry, but this room has timed out for inactivity, please create a new one."

  alias Phoenix.LiveView

  def update_state(socket, server_pid, changes) do
    if Process.alive?(server_pid) do
      GenServer.call(server_pid, {:update_state, changes})

      {:noreply, socket}
    else
      {:noreply, redirect_to_home(socket, {:error, @inactive_msg})}
    end
  end

  def redirect_to_home(socket, {kind, msg}) do
    socket
    |> LiveView.put_flash(kind, msg)
    |> LiveView.redirect(to: "/")
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
