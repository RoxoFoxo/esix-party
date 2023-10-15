defmodule Core.RoomRegistryTest do
  use Core.DataCase

  alias Core.RoomRegistry

  setup do
    Registry.register(RoomRegistry, "FENNEC", :name)

    :ok
  end

  describe "start_link/1" do
    test "registry keys should be set to be unique" do
      assert {:error, {:already_registered, _pid}} =
               Registry.register(RoomRegistry, "FENNEC", :name)
    end
  end

  describe "exists?/1" do
    test "should return true when already registered" do
      assert Core.RoomRegistry.exists?("FENNEC")
    end

    test "should return false when not registered" do
      refute Core.RoomRegistry.exists?("PURPLE")
    end
  end
end
