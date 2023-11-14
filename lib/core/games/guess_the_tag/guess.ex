defmodule Core.Games.GuessTheTag.Guess do
  @enforce_keys [:guesser, :tags]
  defstruct [:guesser, :tags, score: 0, picked_by: []]
end

