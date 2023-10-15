defmodule Core.GameRoom do
  use GenServer

  alias Core.RoomRegistry

  def new do
    DynamicSupervisor.start_child(Core.RoomSupervisor, {__MODULE__, name: generate_new_name()})
  end

  def start_link(name: name) do
    # put name here inside the state later ig
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  defp generate_new_name do
    name =
      1..6
      |> Enum.map(fn _ -> Enum.random(?A..?Z) end)
      |> to_string()

    if RoomRegistry.exists?(name) do
      generate_new_name()
    else
      {:via, Registry, {RoomRegistry, name}}
    end
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  # @impl true
  # def handle_call(_request, _from, state) do
  #   {:reply, state, state}
  # end
end
