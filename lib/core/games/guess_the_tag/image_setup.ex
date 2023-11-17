defmodule Core.Games.GuessTheTag.ImageSetup do
  @tampering_methods ~w[pixelate ripple random_crop]a

  def edit(image_binary) do
    image_binary
    |> Image.from_binary!()
    |> tamper_img(Enum.random(@tampering_methods))
    |> Image.write!(:memory, suffix: ".webp")
    |> Base.encode64()
  end

  defp tamper_img(img, :pixelate),
    do: img |> thumbnail! |> Image.pixelate!(0.07)

  defp tamper_img(img, :ripple),
    do: img |> thumbnail! |> Image.ripple!()

  defp tamper_img(img, :random_crop),
    do: img |> Image.crop!(random_percent(75), random_percent(75), 0.25, 0.25) |> thumbnail!

  defp thumbnail!(img), do: Image.thumbnail!(img, 1080, resize: :down)

  defp random_percent(max), do: 0..max |> Enum.random() |> then(&(&1 * 0.01)) |> Float.round(2)
end
