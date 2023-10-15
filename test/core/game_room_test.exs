defmodule Core.GameRoomTest do
  use Core.DataCase

  alias Core.GameRoom
  alias Core.RoomRegistry

  describe "new/0" do
    test "should create two rooms with different names" do
      assert {:ok, pid1} = GameRoom.new()
      assert {:ok, pid2} = GameRoom.new()

      assert [name1] = Registry.keys(RoomRegistry, pid1)
      assert [name2] = Registry.keys(RoomRegistry, pid2)

      assert name1 != name2
    end
  end

  describe "start_link/1" do
    test "starts a process" do
      assert {:ok, _pid} = GameRoom.start_link(name: {:via, Registry, {RoomRegistry, "FENNEC"}})
    end
  end

  describe "init/1" do
    test "starts a new gameroom" do
      assert {:ok, _pid} = GameRoom.init(%{})
    end
  end
end
