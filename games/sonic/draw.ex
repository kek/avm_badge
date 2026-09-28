defmodule Badge.Sonic.Draw do
  @moduledoc """
  Display items for Sonic in Varberg, built from rects so nothing is loaded
  from flash.

  Sprites are lists of `{dx, dy, w, h, colour}` facing right, topmost part
  first, mirrored for facing left. Every rect is clipped to the panel below
  the title bar, since a rect off the edge is not the driver's to handle.
  """

  alias Badge.Sonic.Level

  @top 26
  @panel_w 320
  @panel_h 240

  @blue 0x1E4FD8
  @light_blue 0x6F9BFF
  @peach 0xF6C28B
  @red 0xE3262E
  @white 0xFFFFFF
  @black 0x101010
  @gold 0xFFD400
  @gold_dark 0xC89400

  @sky [{26, 54, 0x2F7BD6}, {80, 40, 0x4C9BE8}, {120, 28, 0x7DBDF2}, {148, 2, 0xBFE3FA}]
  @hud_bg 0x2F7BD6
  @sea 0x1B5E9E
  @sea_light 0x3C82C4
  @horizon 150

  @head [
    {13, 4, 2, 3, @black},
    {10, 3, 5, 5, @white},
    {17, 8, 2, 2, @black},
    {11, 8, 7, 4, @peach},
    {4, 0, 12, 12, @blue},
    {0, 2, 5, 4, @blue},
    {0, 7, 6, 4, @blue},
    {1, 12, 5, 3, @blue},
    {8, 13, 6, 6, @peach},
    {5, 12, 10, 8, @blue}
  ]

  @stand [{14, 13, 5, 3, @peach}] ++
           @head ++
           [
             {5, 23, 2, 3, @white},
             {13, 23, 2, 3, @white},
             {3, 23, 7, 3, @red},
             {10, 23, 8, 3, @red},
             {6, 20, 3, 3, @blue},
             {11, 20, 3, 3, @blue}
           ]

  @run_a [{15, 11, 5, 3, @peach}] ++
           @head ++
           [
             {0, 22, 7, 3, @red},
             {13, 20, 7, 3, @red},
             {3, 20, 3, 3, @blue},
             {13, 18, 3, 3, @blue}
           ]

  @run_b [{2, 14, 5, 3, @peach}] ++
           @head ++
           [
             {9, 23, 2, 3, @white},
             {6, 23, 9, 3, @red},
             {8, 20, 4, 3, @blue}
           ]

  @ball_body [{6, 6, 8, 20, @blue}, {3, 8, 14, 16, @blue}, {2, 11, 16, 10, @blue}]
  @ball_spots [{5, 9}, {11, 9}, {11, 19}, {5, 19}]

  @crab_colour 0xE5482F
  @crab_dark 0x9E2A1B
  @crab_body [
    {8, 1, 1, 1, @black},
    {14, 1, 1, 1, @black},
    {7, 0, 3, 3, @white},
    {13, 0, 3, 3, @white},
    {8, 3, 1, 2, @crab_dark},
    {14, 3, 1, 2, @crab_dark},
    {0, 1, 5, 5, @crab_colour},
    {17, 1, 5, 5, @crab_colour},
    {3, 5, 16, 7, @crab_colour}
  ]
  @crab [
    @crab_body ++
      [
        {3, 12, 2, 2, @crab_dark},
        {7, 12, 2, 2, @crab_dark},
        {13, 12, 2, 2, @crab_dark},
        {17, 12, 2, 2, @crab_dark}
      ],
    @crab_body ++
      [
        {2, 12, 2, 2, @crab_dark},
        {8, 12, 2, 2, @crab_dark},
        {12, 12, 2, 2, @crab_dark},
        {18, 12, 2, 2, @crab_dark}
      ]
  ]

  @gull_grey 0xA9B4BE
  @gull_tip 0x404850
  @gull_body [
    {20, 3, 1, 1, @black},
    {23, 4, 3, 2, 0xF2B01E},
    {17, 2, 6, 5, @white},
    {5, 5, 14, 6, @white},
    {1, 6, 5, 3, @gull_grey}
  ]
  @gull [
    [{6, 0, 3, 4, @gull_tip}, {9, 0, 7, 4, @gull_grey}] ++ @gull_body,
    [{6, 9, 3, 4, @gull_tip}, {9, 9, 7, 4, @gull_grey}] ++ @gull_body
  ]

  @goat_coat 0xEFE8D8
  @goat_shade 0xD8CFBF
  @goat_horn 0x7A6A55
  @goat_leg 0x8F877A
  @goat_body [
    {22, 4, 1, 1, @black},
    {18, 0, 3, 3, @goat_horn},
    {21, 0, 2, 2, @goat_horn},
    {22, 9, 2, 3, @goat_shade},
    {19, 2, 7, 7, @goat_coat},
    {1, 7, 3, 3, @goat_coat},
    {3, 7, 17, 9, @goat_coat}
  ]
  @goat [
    @goat_body ++ [{5, 16, 3, 6, @goat_leg}, {16, 16, 3, 6, @goat_leg}],
    @goat_body ++ [{7, 16, 3, 6, @goat_leg}, {14, 16, 3, 6, @goat_leg}]
  ]

  @ground_colours %{
    sand: {0xF2DFA0, 0xE3C77E},
    rock: {0xC99A8A, 0xA8786B},
    grass: {0x3FA34D, 0x8A5A2B},
    wall: {0xB5AFA4, 0x8F8A80}
  }

  @kallbadhuset 420
  @fortress 1050

  @doc "The whole panel for a game state, HUD and overlays included."
  def frame(%{phase: :title} = s) do
    title_card() ++ sonic(s, 60, 174) ++ scene(s)
  end

  def frame(%{phase: :clear} = s) do
    clear_card(s) ++ hud(s) ++ sonic(s, s.x - s.cam, s.y) ++ scene(s)
  end

  def frame(%{phase: :over} = s) do
    over_card() ++ hud(s) ++ scene(s)
  end

  def frame(s) do
    hud(s) ++ sonic(s, s.x - s.cam, s.y) ++ scene(s)
  end

  defp scene(s) do
    window = Level.window(s.cam)

    enemies(window.enemies, s) ++
      rings(window.rings, s) ++
      springs(window.springs, s.cam) ++
      posts(s) ++
      ground(window.ground, window.platforms, s.cam) ++
      landmarks(s.cam) ++
      clouds(s.cam) ++
      sea(s.cam, s.clock) ++
      sky()
  end

  # Flickers while hurt, like the original.
  defp sonic(%{hurt: hurt, clock: clock}, _x, _y) when hurt > 0 and rem(clock, 2) == 1, do: []

  defp sonic(s, x, y) do
    case pose(s) do
      :ball -> ball(x, y, s.clock)
      parts -> sprite(parts, x, y, 20, s.face)
    end
  end

  defp pose(%{roll: roll}) when roll != :none, do: :ball
  defp pose(%{phase: :play, ground: true, vx: 0}), do: @stand
  defp pose(%{phase: :play, ground: true, clock: clock}) when rem(clock, 2) == 0, do: @run_a
  defp pose(%{phase: :play, ground: true}), do: @run_b
  defp pose(%{phase: :play, vy: vy}) when vy < 0, do: @run_a
  defp pose(_s), do: @stand

  defp ball(x, y, clock) do
    {sx, sy} = :lists.nth(rem(clock, 4) + 1, @ball_spots)

    rect(x + sx, y + sy, 4, 4, @light_blue) ++ sprite(@ball_body, x, y, 20, 1)
  end

  defp enemies(list, s) do
    :lists.flatmap(
      fn {id, kind, _x0, _x1, _y} = enemy ->
        case :lists.member(id, s.killed) do
          true ->
            []

          false ->
            {x, y, w, _h, facing} = Level.enemy_at(enemy, s.clock)
            frames = enemy_frames(kind)
            parts = :lists.nth(rem(s.clock, 2) + 1, frames)

            sprite(parts, x - s.cam, y, w, facing)
        end
      end,
      list
    )
  end

  defp enemy_frames(:crab), do: @crab
  defp enemy_frames(:gull), do: @gull
  defp enemy_frames(:goat), do: @goat

  # Rings turn by narrowing, as a flat coin seen edge-on would.
  defp rings(list, s) do
    half = :lists.nth(rem(s.clock, 4) + 1, [6, 4, 1, 4])

    :lists.flatmap(
      fn {id, x, y} ->
        case :lists.member(id, s.got) do
          true -> []
          false -> ring(x - s.cam - half, y - 6, 2 * half)
        end
      end,
      list
    )
  end

  defp ring(x, y, w) when w <= 4, do: rect(x, y, w, 12, @gold)

  defp ring(x, y, w) do
    rect(x, y, w, 2, @gold) ++
      rect(x, y + 10, w, 2, @gold) ++
      rect(x, y + 2, 2, 8, @gold_dark) ++ rect(x + w - 2, y + 2, 2, 8, @gold)
  end

  defp springs(list, cam) do
    :lists.flatmap(
      fn {x, top} ->
        rect(x - cam, top - 8, 20, 3, @red) ++ rect(x - cam + 5, top - 5, 10, 5, 0x9A9A9A)
      end,
      list
    )
  end

  defp posts(s) do
    lamps =
      :lists.flatmap(
        fn x ->
          lit =
            case s.check >= x do
              true -> @red
              false -> @light_blue
            end

          rect(x - s.cam - 2, 154, 8, 8, lit) ++ rect(x - s.cam, 160, 4, 40, 0x2B3F8F)
        end,
        Level.checkpoints()
      )

    lamps ++
      flag(Level.goal() - s.cam - 14, 128, 32, 20) ++
      rect(Level.goal() - s.cam, 148, 4, 52, 0x8F8A80)
  end

  defp flag(x, y, w, h) do
    third = div(w, 3)

    rect(x + third, y, div(h, 4), h, 0xFECC02) ++
      rect(x, y + div(h * 2, 5), w, div(h, 5), 0xFECC02) ++ rect(x, y, w, h, 0x006AA7)
  end

  defp ground(blocks, platforms, cam) do
    piers =
      :lists.flatmap(
        fn {x, y, w} ->
          rect(x - cam, y, w, 3, 0xA87440) ++
            rect(x - cam, y + 3, w, 5, 0x8B5A2B) ++
            rect(x - cam + 6, y + 8, 4, @panel_h, 0x5E3C1C) ++
            rect(x - cam + w - 10, y + 8, 4, @panel_h, 0x5E3C1C)
        end,
        platforms
      )

    solid =
      :lists.flatmap(
        fn {x, top, w, kind} ->
          {edge, fill} = Map.fetch!(@ground_colours, kind)

          battlements(kind, x - cam, top, w, edge) ++
            rect(x - cam, top, w, 4, edge) ++ rect(x - cam, top + 4, w, @panel_h, fill)
        end,
        blocks
      )

    piers ++ solid
  end

  defp battlements(:wall, x, top, w, colour) do
    :lists.flatmap(
      fn i -> rect(x + i * 20 + 2, top - 6, 10, 6, colour) end,
      :lists.seq(0, div(w - 12, 20))
    )
  end

  defp battlements(_kind, _x, _top, _w, _colour), do: []

  # Kallbadhuset and the fortress sit far out, scrolling at a quarter speed.
  defp landmarks(cam) do
    far = div(cam, 4)

    kallbadhuset(@kallbadhuset - far) ++ fortress(@fortress - far)
  end

  defp kallbadhuset(x) when x < -100 or x > @panel_w, do: []

  defp kallbadhuset(x) do
    dome = 0x5FA89A
    cream = 0xF1E3B3

    rect(x + 8, 80, 2, 6, @black) ++
      rect(x + 6, 86, 6, 6, dome) ++
      rect(x + 3, 92, 12, 8, dome) ++
      rect(x + 80, 80, 2, 6, @black) ++
      rect(x + 78, 86, 6, 6, dome) ++
      rect(x + 75, 92, 12, 8, dome) ++
      rect(x + 40, 92, 10, 6, dome) ++
      rect(x + 36, 98, 18, 14, dome) ++
      rect(x + 12, 118, 6, 8, 0x3B5F7A) ++
      rect(x + 30, 118, 6, 8, 0x3B5F7A) ++
      rect(x + 54, 118, 6, 8, 0x3B5F7A) ++
      rect(x + 72, 118, 6, 8, 0x3B5F7A) ++
      rect(x + 2, 100, 14, 38, cream) ++
      rect(x + 74, 100, 14, 38, cream) ++
      rect(x + 6, 112, 78, 26, cream) ++
      rect(x, 138, 90, 5, 0x8C6B4A) ++
      :lists.flatmap(fn i -> rect(x + 4 + i * 20, 143, 3, 12, 0x5E3C1C) end, [0, 1, 2, 3, 4])
  end

  defp fortress(x) when x < -200 or x > @panel_w, do: []

  defp fortress(x) do
    stone = 0xA39E94
    rock = 0x6E625C

    flag(x + 58, 30, 14, 9) ++
      rect(x + 56, 30, 2, 18, @black) ++
      rect(x + 38, 48, 38, 8, 0x3E7D6A) ++
      rect(x + 50, 64, 6, 8, @black) ++
      rect(x + 40, 56, 34, 30, 0xB5AFA4) ++
      rect(x + 90, 74, 40, 10, 0xB0442F) ++
      rect(x + 92, 84, 36, 10, 0xE8D7B5) ++
      :lists.flatmap(fn i -> rect(x + 10 + i * 16, 78, 8, 6, stone) end, :lists.seq(0, 8)) ++
      rect(x + 10, 84, 140, 26, stone) ++
      rect(x, 108, 160, 14, rock) ++
      rect(x - 20, 120, 200, 30, rock)
  end

  defp clouds(cam) do
    drift = div(cam, 8)

    :lists.flatmap(
      fn {cx, cy} ->
        x = rem(cx - rem(drift, 480) + 480, 480) - 80

        rect(x + 10, cy, 30, 8, @white) ++ rect(x, cy + 6, 56, 8, @white)
      end,
      [{40, 44}, {200, 60}, {330, 38}, {450, 70}]
    )
  end

  defp sea(cam, clock) do
    drift = rem(div(cam, 2) + clock, 360)

    waves =
      :lists.flatmap(
        fn {phase, y} ->
          x = rem(phase - drift + 360, 360) - 40
          rect(x, y, 40, 2, @sea_light)
        end,
        [{0, 158}, {150, 166}, {260, 178}, {80, 192}, {210, 206}, {30, 222}]
      )

    waves ++ rect(0, @horizon, @panel_w, @panel_h - @horizon, @sea)
  end

  defp sky do
    :lists.flatmap(fn {y, h, colour} -> rect(0, y, @panel_w, h, colour) end, @sky)
  end

  defp hud(s) do
    rings =
      case s.rings == 0 and rem(s.clock, 4) < 2 do
        true -> @red
        false -> @gold
      end

    [
      text(4, 30, @gold, "SCORE"),
      text(52, 30, @white, number(s.score)),
      text(116, 30, rings, "RINGS"),
      text(164, 30, @white, number(s.rings)),
      text(204, 30, @gold, "TIME"),
      text(244, 30, @white, clock_face(s.t)),
      text(292, 30, @white, "x" <> number(s.lives))
    ]
  end

  defp title_card do
    [
      line(48, @white, "SONIC THE HEDGEHOG"),
      line(66, @gold, "i VARBERG"),
      card_text(72, 92, @white, "Left/Right  run"),
      card_text(72, 108, @white, "Up/Enter    jump"),
      card_text(72, 124, @white, "Down        roll"),
      line(148, @gold, "Enter to start"),
      card(40, 40, 240, 130)
    ]
  end

  defp clear_card(s) do
    got = number(s.rings) <> "/" <> number(Level.ring_count())

    [
      line(60, @white, "SONIC GOT THROUGH"),
      line(80, @gold, Badge.Text.cp437("TILL FÄSTNINGEN")),
      card_text(84, 104, @white, "BONUS  " <> number(s.bonus)),
      card_text(84, 120, @white, "SCORE  " <> number(s.score)),
      card_text(84, 136, @white, "RINGS  " <> got)
    ] ++ prompt(s) ++ [card(48, 52, 224, 128)]
  end

  defp over_card do
    [
      line(98, @red, "GAME OVER"),
      line(118, @white, "Enter to retry"),
      card(80, 90, 160, 48)
    ]
  end

  defp prompt(%{timer: 0}), do: [line(158, @gold, "Enter to replay")]
  defp prompt(_s), do: []

  # Centred on the panel, on a card.
  defp line(y, colour, body),
    do: card_text(div(@panel_w - 8 * byte_size(body), 2), y, colour, body)

  defp card_text(x, y, colour, body), do: text(x, y, colour, @blue, body)

  defp card(x, y, w, h), do: {:rect, x, y, w, h, @blue}

  defp text(x, y, colour, body), do: text(x, y, colour, @hud_bg, body)

  defp text(x, y, colour, bg, body), do: {:text, x, y, :default16px, colour, bg, body}

  defp number(n), do: :erlang.integer_to_binary(n)

  defp clock_face(ticks) do
    seconds = div(ticks, 10)
    tens = div(rem(seconds, 60), 10)
    ones = rem(seconds, 10)

    number(div(seconds, 60)) <> ":" <> number(tens) <> number(ones)
  end

  @doc "Parts of a sprite at `x, y`, mirrored when `facing` is -1."
  def sprite(parts, x, y, w, facing) do
    :lists.flatmap(
      fn {dx, dy, pw, ph, colour} ->
        case facing do
          1 -> rect(x + dx, y + dy, pw, ph, colour)
          _left -> rect(x + w - dx - pw, y + dy, pw, ph, colour)
        end
      end,
      parts
    )
  end

  @doc "A rect clipped to the panel below the title bar, or nothing if none of it shows."
  def rect(x, y, w, h, colour) do
    left = max(x, 0)
    top = max(y, @top)
    right = min(x + w, @panel_w)
    bottom = min(y + h, @panel_h)

    case right > left and bottom > top do
      true -> [{:rect, left, top, right - left, bottom - top, colour}]
      false -> []
    end
  end
end
