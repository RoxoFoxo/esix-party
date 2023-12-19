defmodule Core.Games.GuessTheTag.ImageSetup do
  require Integer

  @tampering_methods ~w[pixelate ripple random_crop ring checkers]a

  def normal_to_memory(image_binary) do
    image_binary
    |> Image.from_binary!()
    |> resize_img
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
    do: img |> resize_img |> Image.pixelate!(0.07)

  defp tamper_img(img, :ripple),
    do: img |> resize_img |> Image.ripple!()

  # This being 75 gave me an error once, so I changed both to 74.
  defp tamper_img(img, :random_crop),
    do: img |> Image.crop!(random_percent(74), random_percent(74), 0.25, 0.25) |> resize_img

  defp tamper_img(img, :ring) do
    shape = {width, height, _} = Image.shape(img)

    left = div(width, 20)
    top = div(height, 20)
    rect_width = width - left * 2
    rect_height = height - top * 2

    stroke_width =
      shape
      |> get_smaller_dimension()
      |> div(4)

    img
    |> Image.Draw.rect!(left, top, rect_width, rect_height,
      stroke_width: stroke_width,
      fill: false
    )
    |> resize_img
  end

  defp tamper_img(img, :checkers) do
    shape = {width, height, _} = Image.shape(img)

    square_size =
      shape
      |> get_smaller_dimension()
      |> div(1000)
      |> then(&((&1 + 1) * 150))

    squares_horizontal = div(width, square_size) + 1
    squares_vertical = div(height, square_size) + 1

    img
    |> checkers(square_size, squares_horizontal, squares_vertical)
    |> resize_img
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

  defp get_smaller_dimension({width, height, _}) when width <= height, do: width
  defp get_smaller_dimension({width, height, _}) when width > height, do: height

  defp resize_img(img), do: Image.thumbnail!(img, 1080, resize: :down)

  defp random_percent(max), do: 0..max |> Enum.random() |> then(&(&1 * 0.01)) |> Float.round(2)
end
