defmodule Core.Games.GuessTheTag.ImageSetup do
  @tampering_methods ~w[pixelate ripple random_crop ring]a

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

  # This being 75 gave me an error once, so I changed both to 74.
  defp tamper_img(img, :random_crop),
    do: img |> Image.crop!(random_percent(74), random_percent(74), 0.25, 0.25) |> thumbnail!

  defp tamper_img(img, :ring) do
    default_width = Image.width(img)
    default_height = Image.height(img)

    left = div(default_width, 20)
    top = div(default_height, 20)
    width = default_width - left * 2
    height = default_height - top * 2
    stroke_width = div(default_width, 4)

    img
    |> Image.Draw.rect!(left, top, width, height, stroke_width: stroke_width, fill: false)
    |> thumbnail!
  end

  defp thumbnail!(img), do: Image.thumbnail!(img, 1080, resize: :down)

  defp random_percent(max), do: 0..max |> Enum.random() |> then(&(&1 * 0.01)) |> Float.round(2)
end
