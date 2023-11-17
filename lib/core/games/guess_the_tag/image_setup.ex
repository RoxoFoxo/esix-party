defmodule Core.Games.GuessTheTag.ImageSetup do
  @tampering_methods ~w[pixelate]a

  def edit(image_binary) do
    image_binary
    |> Image.from_binary!()
    |> tamper_img(Enum.random(@tampering_methods))
    |> Image.write!(:memory, suffix: ".jpg")
    |> Base.encode64()
  end

  defp tamper_img(img, :pixelate), do: Image.pixelate!(img, 0.03)
end
