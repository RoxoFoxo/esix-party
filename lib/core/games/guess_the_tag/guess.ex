defmodule Core.Games.GuessTheTag.Guess do
  @enforce_keys [:guesser, :tags]
  defstruct [:guesser, :tags, :score, picked_by: []]
end

