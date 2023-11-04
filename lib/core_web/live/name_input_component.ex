defmodule CoreWeb.NameInputComponent do
  use CoreWeb, :live_component

  alias Core.Player

  @in_use_msg "Name is already in use!"
  @empty_msg "Yeah that's the input box, write a name on it!"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id="name_input_modal" show>
        <p>Please input your name:</p>
        <.simple_form
          for={@form}
          id="new_player"
          phx-target={@myself}
          phx-change="clear_msg"
          phx-submit="name_submit"
        >
          <.input field={@form[:name]} type="text" autocomplete="off" maxlength="12" label="Username" />
          <:actions>
            <.button>Submit</.button>
          </:actions>
        </.simple_form>
        <%= if @fail_msg do %>
          <%= @fail_msg %>
        <% end %>
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket, %{
       form: to_form(%{}),
       fail_msg: nil
     })}
  end

  @impl true
  def handle_event("clear_msg", _params, socket) do
    {:noreply, assign(socket, :fail_msg, nil)}
  end

  def handle_event("name_submit", %{"name" => player_name}, socket) do
    players = socket.assigns.state.players

    with false <- name_in_use?(player_name, players) && :in_use,
         false <- player_name == "" && :empty do
      owner? = players == []

      new_player_list = [%Player{name: player_name, owner?: owner?} | players]

      GenServer.call(
        socket.assigns.server_pid,
        {:update_state, socket.assigns.state.name, %{players: new_player_list}}
      )

      send(self(), {:name_submit, %{current_player: player_name}})
      {:noreply, socket}
    else
      :in_use ->
        {:noreply, assign(socket, fail_msg: @in_use_msg)}

      :empty ->
        {:noreply, assign(socket, fail_msg: @empty_msg)}
    end
  end

  defp name_in_use?(player_name, players), do: Enum.any?(players, &(&1.name == player_name))
end
