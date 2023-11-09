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
end
