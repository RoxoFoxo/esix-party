defmodule Core.Games.GuessTheTag.Guess do
  defstruct [:guesser, :tags, score: 0, picked_by: []]
end

