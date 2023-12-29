defmodule Core.GameUtils do
  def flatten_tags(tags), do: tags |> Map.values() |> List.flatten()
end
