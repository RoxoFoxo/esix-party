defmodule CoreWeb.NameInputComponent do
  use CoreWeb, :live_component

  import CoreWeb.RoomUtils

  alias Core.Player

  @in_use_msg "Name is already in use!"
  @esix_msg "Hey, that's my name! Come up with something different!"
  @empty_msg "Yeah that's the input box, write a name on it!"
  @crown_msg "Sorry, but only the room owner can be royalty!"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id="name_input_modal" show>
        <.simple_form
          for={@form}
          id="new_player"
          phx-target={@myself}
          phx-change="clear_msg"
          phx-submit="name_submit"
        >
          <.input
            field={@form[:name]}
            type="text"
            autocomplete="off"
            maxlength="12"
            label="Enter a username:"
          />
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

  def handle_event(
        "name_submit",
        %{"name" => player_name},
        %{assigns: %{state: %{players: players}}} = socket
      ) do
    with false <- player_name == "" && :empty,
         false <- player_name =~ ~r'^eSix$'i && :esix,
         false <- String.contains?(player_name, "👑") && :crown,
         false <- name_in_use?(player_name, players) && :in_use do
      send(self(), {:name_submit, %{current_player: player_name}})

      owner? = players == []
      new_players = [%Player{name: player_name, owner?: owner?} | players]

      {:noreply, update_state(socket, %{players: new_players})}
    else
      :empty ->
        {:noreply, assign(socket, fail_msg: @empty_msg)}

      :esix ->
        {:noreply, assign(socket, fail_msg: @esix_msg)}

      :crown ->
        {:noreply, assign(socket, fail_msg: @crown_msg)}

      :in_use ->
        {:noreply, assign(socket, fail_msg: @in_use_msg)}
    end
  end

  defp name_in_use?(player_name, players), do: Enum.any?(players, &(&1.name == player_name))
end
