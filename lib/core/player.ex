defmodule Core.Player do
  @enforce_keys [:name]
  defstruct [:name, owner?: false, score: 0]
end
