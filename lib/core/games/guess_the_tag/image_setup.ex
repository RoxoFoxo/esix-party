defmodule Core.Games.GuessTheTag.ImageSetup do
  require Integer

  @tampering_methods ~w[pixelate ripple random_crop ring checkers]a

  def normal_to_memory(image_binary) do
    image_binary
    |> Image.from_binary!()
    |> thumbnail!()
    |> Image.write!(:memory, suffix: ".webp")
    |> Base.encode64()
  end

  def tamper_to_memory(image_binary) do
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

  defp tamper_img(img, :checkers) do
    default_width = Image.width(img)
    default_height = Image.height(img)

    square_size =
      case default_width >= default_height do
        true -> (div(default_width, 1000) + 1) * 150
        false -> (div(default_height, 1000) + 1) * 150
      end

    squares_horizontal = div(default_width, square_size) + 1
    squares_vertical = div(default_height, square_size) + 1

    img
    |> checkers(square_size, squares_horizontal, squares_vertical)
    |> thumbnail!
  end

  defp checkers(img, square_size, squares_horizontal, squares_vertical) do
    pattern = Enum.random([:pattern1, :pattern2])

    for h <- 0..squares_horizontal, v <- 0..squares_vertical do
      if follows_pattern?(h, v, pattern) do
        {square_size * h, square_size * v}
      end
    end
    |> Enum.reject(&(&1 == nil))
    |> Enum.reduce(img, fn {left, top}, acc ->
      Image.Draw.rect!(acc, left, top, square_size, square_size)
    end)
  end

  defp follows_pattern?(h, v, pattern) do
    case pattern do
      :pattern1 ->
        (Integer.is_even(h) and Integer.is_odd(v)) or (Integer.is_even(v) and Integer.is_odd(h))

      :pattern2 ->
        (Integer.is_even(h) and Integer.is_even(v)) or (Integer.is_odd(v) and Integer.is_odd(h))
    end
  end

  defp thumbnail!(img), do: Image.thumbnail!(img, 1080, resize: :down)

  defp random_percent(max), do: 0..max |> Enum.random() |> then(&(&1 * 0.01)) |> Float.round(2)
end
