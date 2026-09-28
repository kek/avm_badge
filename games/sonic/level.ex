defmodule Badge.Sonic.Level do
  @moduledoc """
  The one act of Sonic in Varberg: the beach, Kallbadhuset's pier, the rocks
  and the climb to Varbergs fästning.

  Everything is compiled in and split into chunks one panel wide, so
  `window/1` hands back only the pieces near the camera. Coordinates are
  world pixels; y matches the panel, since the act never scrolls vertically.

  - ground: `{x, top, w, kind}`, solid from `top` to the bottom of the panel
  - platforms: `{x, y, w}`, landed on from above only
  - springs: `{x, top}`, standing on the ground at `top`
  - rings: `{id, x, y}`, centred on `x, y`
  - enemies: `{id, kind, x0, x1, y}`, patrolling between `x0` and `x1`
  """

  @chunk 320
  @width 4040
  @start {40, 174}
  @goal 3900
  @checkpoints [1600, 3060]

  # Walls come before the grass under them so they draw on top.
  @ground [
    {0, 200, 640, :sand},
    {1540, 200, 360, :rock},
    {1900, 176, 200, :rock},
    {2100, 152, 220, :rock},
    {2320, 200, 700, :grass},
    {3200, 168, 120, :wall},
    {3440, 144, 100, :wall},
    {3020, 200, 1020, :grass}
  ]

  @platforms [
    {720, 190, 160},
    {940, 176, 140},
    {1140, 160, 120},
    {1320, 176, 170},
    {2340, 70, 160},
    {2560, 90, 140},
    {2760, 110, 160}
  ]

  @springs [{2270, 152}, {3380, 200}]

  @ring_spots (
                row = fn x0, y, n, gap -> for i <- 0..(n - 1), do: {x0 + i * gap, y} end

                arc = fn x0, y, n, gap ->
                  mid = (n - 1) / 2

                  for i <- 0..(n - 1),
                      do: {x0 + i * gap, y + round((i - mid) * (i - mid) * 5)}
                end

                row.(220, 178, 6, 28) ++
                  arc.(646, 150, 5, 18) ++
                  row.(760, 164, 4, 28) ++
                  arc.(886, 140, 4, 18) ++
                  row.(975, 150, 4, 28) ++
                  arc.(1090, 128, 4, 16) ++
                  row.(1170, 134, 3, 28) ++
                  row.(1350, 150, 5, 28) ++
                  row.(1700, 178, 5, 28) ++
                  row.(1950, 154, 4, 28) ++
                  row.(2380, 48, 5, 26) ++
                  row.(2590, 68, 4, 28) ++
                  row.(2790, 88, 5, 28) ++
                  row.(3100, 178, 4, 28) ++
                  arc.(3330, 130, 5, 20) ++
                  row.(3600, 178, 6, 28)
              )

  @rings for {{x, y}, id} <- Enum.with_index(@ring_spots), do: {id, x, y}

  @enemies [
    {0, :crab, 420, 600, 186},
    {1, :gull, 880, 1080, 120},
    {2, :gull, 1180, 1380, 104},
    {3, :crab, 1620, 1860, 186},
    {4, :crab, 2140, 2240, 138},
    {5, :goat, 2420, 2620, 178},
    {6, :gull, 2700, 2900, 60},
    {7, :goat, 3060, 3180, 178},
    {8, :crab, 3560, 3760, 186},
    {9, :gull, 3620, 3820, 110}
  ]

  @chunks div(@width + @chunk - 1, @chunk)

  # A piece of ground or platform that crosses a chunk edge is cut there, so
  # every piece belongs to exactly one chunk.
  cut = fn x, w, fun ->
    for n <- div(x, @chunk)..div(x + w - 1, @chunk) do
      left = max(x, n * @chunk)
      right = min(x + w, (n + 1) * @chunk)
      {n, fun.(left, right - left)}
    end
  end

  pieces_in = fn pieces, n -> for {^n, piece} <- pieces, do: piece end

  ground_pieces =
    Enum.flat_map(@ground, fn {x, top, w, kind} ->
      cut.(x, w, fn left, width -> {left, top, width, kind} end)
    end)

  platform_pieces =
    Enum.flat_map(@platforms, fn {x, y, w} ->
      cut.(x, w, fn left, width -> {left, y, width} end)
    end)

  for n <- 0..(@chunks - 1) do
    contents = %{
      ground: pieces_in.(ground_pieces, n),
      platforms: pieces_in.(platform_pieces, n),
      springs: for({x, _top} = s <- @springs, div(x, @chunk) == n, do: s),
      rings: for({_id, x, _y} = r <- @rings, div(x, @chunk) == n, do: r),
      enemies: for({_id, _kind, x0, _x1, _y} = e <- @enemies, div(x0, @chunk) == n, do: e)
    }

    defp chunk(unquote(n)), do: unquote(Macro.escape(contents))
  end

  defp chunk(_n), do: %{ground: [], platforms: [], springs: [], rings: [], enemies: []}

  @doc "Width of the act in pixels."
  def width, do: @width

  @doc "Where Sonic stands at the start, top-left of his box."
  def start, do: @start

  @doc "The x that ends the act."
  def goal, do: @goal

  @doc "Lamp posts, left to right; passing one makes it the respawn point."
  def checkpoints, do: @checkpoints

  @doc "How many rings the act holds."
  def ring_count, do: length(@rings)

  @doc "Every piece within a panel either side of the camera's chunk."
  def window(cam) do
    n = div(cam, @chunk)

    merge(chunk(n - 1), merge(chunk(n), chunk(n + 1)))
  end

  defp merge(a, b) do
    %{
      ground: a.ground ++ b.ground,
      platforms: a.platforms ++ b.platforms,
      springs: a.springs ++ b.springs,
      rings: a.rings ++ b.rings,
      enemies: a.enemies ++ b.enemies
    }
  end

  @doc "An enemy's box and heading at `clock`: `{x, y, w, h, facing}`."
  def enemy_at({_id, kind, x0, x1, y}, clock) do
    span = x1 - x0
    travel = rem(clock * speed(kind), 2 * span)

    {x, facing} =
      case travel < span do
        true -> {x0 + travel, 1}
        false -> {x0 + 2 * span - travel, -1}
      end

    {w, h} = size(kind)

    {x, y + bob(kind, clock), w, h, facing}
  end

  @doc "The box size of an enemy kind."
  def size(:crab), do: {22, 14}
  def size(:gull), do: {26, 14}
  def size(:goat), do: {26, 22}

  defp speed(:crab), do: 3
  defp speed(:gull), do: 5
  defp speed(:goat), do: 7

  defp bob(:gull, clock), do: rem(clock, 4) * 2 - 3
  defp bob(_kind, _clock), do: 0
end
