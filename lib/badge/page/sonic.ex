defmodule Badge.Page.Sonic do
  @moduledoc """
  Sonic the Hedgehog, in Varberg: one act from the beach past Kallbadhuset
  to Varbergs fästning.

  Left and Right run, Up, Enter or Space jump, Down rolls. The game is
  `Badge.Sonic`; this page feeds it keys and ticks and draws it. Esc is never
  taken, so the router can always go home.

  Everything is drawn from rects. Sprites and landmarks are binaries of
  `<<dx, dy, w, h, colour>>` with the colour an index into `@palette`, drawn
  back to front into one list, so the topmost item ends up at its head. Every
  rect is clipped to the panel below the title bar.
  """

  use Badge.Page

  alias Badge.Sonic

  @top 26

  @palette {0x1E4FD8, 0x6F9BFF, 0xF6C28B, 0xE3262E, 0xFFFFFF, 0x101010, 0xFFD400, 0xC89400,
            0xE5482F, 0x9E2A1B, 0xA9B4BE, 0x404850, 0xF2B01E, 0xEFE8D8, 0xD8CFBF, 0x7A6A55,
            0x8F877A, 0x5FA89A, 0xF1E3B3, 0x3B5F7A, 0x8C6B4A, 0x5E3C1C, 0xA39E94, 0x6E625C,
            0xB5AFA4, 0x3E7D6A, 0xB0442F, 0xE8D7B5, 0x006AA7, 0xFECC02, 0x9A9A9A, 0x2B3F8F}

  pack = fn parts ->
    colours = Tuple.to_list(@palette)

    for {dx, dy, w, h, c} <- Enum.reverse(parts), into: <<>> do
      <<dx, dy, w, h, Enum.find_index(colours, &(&1 == c))>>
    end
  end

  {blue, peach, red, white, black} = {0x1E4FD8, 0xF6C28B, 0xE3262E, 0xFFFFFF, 0x101010}

  # Parts are listed topmost first, as a reader looks at the sprite.
  head = [
    {13, 4, 2, 3, black},
    {10, 3, 5, 5, white},
    {17, 8, 2, 2, black},
    {11, 8, 7, 4, peach},
    {4, 0, 12, 12, blue},
    {0, 2, 5, 4, blue},
    {0, 7, 6, 4, blue},
    {1, 12, 5, 3, blue},
    {8, 13, 6, 6, peach},
    {5, 12, 10, 8, blue}
  ]

  @stand pack.(
           [{14, 13, 5, 3, peach}] ++
             head ++
             [
               {5, 23, 2, 3, white},
               {13, 23, 2, 3, white},
               {3, 23, 7, 3, red},
               {10, 23, 8, 3, red},
               {6, 20, 3, 3, blue},
               {11, 20, 3, 3, blue}
             ]
         )

  @run_a pack.(
           [{15, 11, 5, 3, peach}] ++
             head ++
             [{0, 22, 7, 3, red}, {13, 20, 7, 3, red}, {3, 20, 3, 3, blue}, {13, 18, 3, 3, blue}]
         )

  @run_b pack.(
           [{2, 14, 5, 3, peach}] ++
             head ++ [{9, 23, 2, 3, white}, {6, 23, 9, 3, red}, {8, 20, 4, 3, blue}]
         )

  @ball pack.([{6, 6, 8, 20, blue}, {3, 8, 14, 16, blue}, {2, 11, 16, 10, blue}])
  @ball_spots {{5, 9}, {11, 9}, {11, 19}, {5, 19}}

  {crab, crab_dark} = {0xE5482F, 0x9E2A1B}

  crab_body = [
    {8, 1, 1, 1, black},
    {14, 1, 1, 1, black},
    {7, 0, 3, 3, white},
    {13, 0, 3, 3, white},
    {8, 3, 1, 2, crab_dark},
    {14, 3, 1, 2, crab_dark},
    {0, 1, 5, 5, crab},
    {17, 1, 5, 5, crab},
    {3, 5, 16, 7, crab}
  ]

  legs = fn xs -> for x <- xs, do: {x, 12, 2, 2, crab_dark} end

  @crab {pack.(crab_body ++ legs.([3, 7, 13, 17])), pack.(crab_body ++ legs.([2, 8, 12, 18]))}

  {grey, tip} = {0xA9B4BE, 0x404850}

  gull_body = [
    {20, 3, 1, 1, black},
    {23, 4, 3, 2, 0xF2B01E},
    {17, 2, 6, 5, white},
    {5, 5, 14, 6, white},
    {1, 6, 5, 3, grey}
  ]

  @gull {pack.([{6, 0, 3, 4, tip}, {9, 0, 7, 4, grey}] ++ gull_body),
         pack.([{6, 9, 3, 4, tip}, {9, 9, 7, 4, grey}] ++ gull_body)}

  {coat, horn, hoof} = {0xEFE8D8, 0x7A6A55, 0x8F877A}

  goat_body = [
    {22, 4, 1, 1, black},
    {18, 0, 3, 3, horn},
    {21, 0, 2, 2, horn},
    {22, 9, 2, 3, 0xD8CFBF},
    {19, 2, 7, 7, coat},
    {1, 7, 3, 3, coat},
    {3, 7, 17, 9, coat}
  ]

  @goat {pack.(goat_body ++ [{5, 16, 3, 6, hoof}, {16, 16, 3, 6, hoof}]),
         pack.(goat_body ++ [{7, 16, 3, 6, hoof}, {14, 16, 3, 6, hoof}])}

  flag = fn x, y ->
    [{x + 5, y, 3, 9, 0xFECC02}, {x, y + 3, 14, 3, 0xFECC02}, {x, y, 14, 9, 0x006AA7}]
  end

  {dome, cream, pane, stilt} = {0x5FA89A, 0xF1E3B3, 0x3B5F7A, 0x5E3C1C}

  # Kallbadhuset, from (x, 80): onion domes, towers, windows, stilts in the sea.
  @kallbadhuset pack.(
                  [
                    {8, 0, 2, 6, black},
                    {6, 6, 6, 6, dome},
                    {3, 12, 12, 8, dome},
                    {80, 0, 2, 6, black},
                    {78, 6, 6, 6, dome},
                    {75, 12, 12, 8, dome},
                    {40, 12, 10, 6, dome},
                    {36, 18, 18, 14, dome}
                  ] ++
                    for(wx <- [12, 30, 54, 72], do: {wx, 38, 6, 8, pane}) ++
                    [
                      {2, 20, 14, 38, cream},
                      {74, 20, 14, 38, cream},
                      {6, 32, 78, 26, cream},
                      {0, 58, 90, 5, 0x8C6B4A}
                    ] ++ for(i <- 0..4, do: {4 + i * 20, 63, 3, 12, stilt})
                )

  {stone, rock} = {0xA39E94, 0x6E625C}

  # Varbergs fästning, from (x - 20, 30): the keep and its flag, walls, the rock it stands on.
  @fortress pack.(
              flag.(78, 0) ++
                [
                  {76, 0, 2, 18, black},
                  {58, 18, 38, 8, 0x3E7D6A},
                  {70, 34, 6, 8, black},
                  {60, 26, 34, 30, 0xB5AFA4},
                  {110, 44, 40, 10, 0xB0442F},
                  {112, 54, 36, 10, 0xE8D7B5}
                ] ++
                for(i <- 0..8, do: {30 + i * 16, 48, 8, 6, stone}) ++
                [{30, 54, 140, 26, stone}, {20, 78, 160, 14, rock}, {0, 90, 200, 30, rock}]
            )

  @goal_flag pack.(for({x, y, w, h, c} <- flag.(0, 0), do: {x * 2, y * 2, w * 2, h * 2, c}))

  @sky [{26, 54, 0x2F7BD6}, {80, 40, 0x4C9BE8}, {120, 28, 0x7DBDF2}, {148, 2, 0xBFE3FA}]
  @hud_bg 0x2F7BD6
  @card 0x1E4FD8
  @gold 0xFFD400

  @impl true
  def title, do: "Sonic"

  @impl true
  def icon, do: :diamond

  @impl true
  def init, do: Sonic.new()

  @impl true
  def handle_key({:nav, _key}, _state), do: :ignore
  def handle_key(event, state), do: Sonic.press(state, event)

  @impl true
  def tick(state), do: Sonic.step(state)

  @impl true
  def refresh(%{phase: phase}) when phase == :play or phase == :dead, do: 100
  def refresh(_state), do: 200

  @impl true
  def render(%{cam: cam, clock: clock, check: check, got: got, killed: killed} = s) do
    %{ground: ground, piers: piers, springs: springs, rings: rings, enemies: enemies} =
      Sonic.window(cam)

    []
    |> sky()
    |> sea(cam, clock)
    |> clouds(cam)
    |> sprite(@kallbadhuset, 420 - div(cam, 4), 80, 0, 1)
    |> sprite(@fortress, 1030 - div(cam, 4), 30, 0, 1)
    |> ground(ground, cam)
    |> piers(piers, cam)
    |> springs(springs, cam)
    |> posts(check, cam)
    |> rings(rings, got, cam, clock)
    |> enemies(enemies, killed, cam, clock)
    |> hero(s)
    |> overlay(s)
  end

  defp sky(acc), do: :lists.foldl(fn {y, h, c}, acc -> rect(0, y, 320, h, c, acc) end, acc, @sky)

  defp sea(acc, cam, clock) do
    drift = rem(div(cam, 2) + clock, 360)
    acc = rect(0, 150, 320, 90, 0x1B5E9E, acc)

    :lists.foldl(
      fn {phase, y}, acc -> rect(rem(phase - drift + 360, 360) - 40, y, 40, 2, 0x3C82C4, acc) end,
      acc,
      [{0, 158}, {150, 166}, {260, 178}, {80, 192}, {210, 206}, {30, 222}]
    )
  end

  defp clouds(acc, cam) do
    drift = rem(div(cam, 8), 480)

    :lists.foldl(
      fn {cx, cy}, acc ->
        x = rem(cx - drift + 480, 480) - 80
        rect(x + 10, cy, 30, 8, 0xFFFFFF, rect(x, cy + 6, 56, 8, 0xFFFFFF, acc))
      end,
      acc,
      [{40, 44}, {200, 60}, {330, 38}, {450, 70}]
    )
  end

  defp ground(acc, blocks, cam) do
    :lists.foldl(
      fn {x, top, w, kind}, acc ->
        {edge, fill} = soil(kind)
        acc = rect(x - cam, top, w, 4, edge, rect(x - cam, top + 4, w, 240, fill, acc))

        case kind do
          :wall ->
            :lists.foldl(
              fn i, acc -> rect(x - cam + i * 20 + 2, top - 6, 10, 6, edge, acc) end,
              acc,
              :lists.seq(0, div(w - 12, 20))
            )

          _ ->
            acc
        end
      end,
      acc,
      blocks
    )
  end

  defp soil(:sand), do: {0xF2DFA0, 0xE3C77E}
  defp soil(:rock), do: {0xC99A8A, 0xA8786B}
  defp soil(:grass), do: {0x3FA34D, 0x8A5A2B}
  defp soil(:wall), do: {0xB5AFA4, 0x8F8A80}

  defp piers(acc, piers, cam) do
    :lists.foldl(
      fn {x, y, w}, acc ->
        acc = rect(x - cam + 6, y + 8, 4, 240, 0x5E3C1C, acc)
        acc = rect(x - cam + w - 10, y + 8, 4, 240, 0x5E3C1C, acc)
        rect(x - cam, y, w, 3, 0xA87440, rect(x - cam, y + 3, w, 5, 0x8B5A2B, acc))
      end,
      acc,
      piers
    )
  end

  defp springs(acc, springs, cam) do
    :lists.foldl(
      fn {x, top}, acc ->
        rect(x - cam, top - 8, 20, 3, 0xE3262E, rect(x - cam + 5, top - 5, 10, 5, 0x9A9A9A, acc))
      end,
      acc,
      springs
    )
  end

  defp posts(acc, check, cam) do
    acc =
      :lists.foldl(
        fn x, acc ->
          lamp = if check >= x, do: 0xE3262E, else: 0x6F9BFF
          rect(x - cam - 2, 154, 8, 8, lamp, rect(x - cam, 160, 4, 40, 0x2B3F8F, acc))
        end,
        acc,
        Sonic.checkpoints()
      )

    goal = Sonic.goal() - cam
    sprite(rect(goal, 148, 4, 52, 0x8F8A80, acc), @goal_flag, goal - 14, 128, 0, 1)
  end

  # Rings turn by narrowing, as a coin seen edge-on would.
  defp rings(acc, rings, got, cam, clock) do
    half = elem({6, 4, 1, 4}, rem(clock, 4))

    :lists.foldl(
      fn {id, x, y}, acc ->
        case :lists.member(id, got) do
          true -> acc
          false -> ring(acc, x - cam - half, y - 6, 2 * half)
        end
      end,
      acc,
      rings
    )
  end

  defp ring(acc, x, y, w) when w <= 4, do: rect(x, y, w, 12, @gold, acc)

  defp ring(acc, x, y, w) do
    acc = rect(x, y, w, 2, @gold, rect(x, y + 10, w, 2, @gold, acc))
    rect(x, y + 2, 2, 8, 0xC89400, rect(x + w - 2, y + 2, 2, 8, @gold, acc))
  end

  defp enemies(acc, enemies, killed, cam, clock) do
    :lists.foldl(
      fn {id, kind, _, _, _} = enemy, acc ->
        case :lists.member(id, killed) do
          true ->
            acc

          false ->
            {x, y, w, _h, facing} = Sonic.enemy_at(enemy, clock)
            sprite(acc, elem(frames(kind), rem(clock, 2)), x - cam, y, w, facing)
        end
      end,
      acc,
      enemies
    )
  end

  defp frames(:crab), do: @crab
  defp frames(:gull), do: @gull
  defp frames(:goat), do: @goat

  defp hero(acc, %{phase: :over}), do: acc
  defp hero(acc, %{hurt: hurt, clock: clock}) when hurt > 0 and rem(clock, 2) == 1, do: acc
  defp hero(acc, %{phase: :title}), do: sprite(acc, @stand, 60, 174, 20, 1)

  defp hero(acc, %{roll: roll, clock: clock, x: x, y: y, cam: cam}) when roll != :none do
    {sx, sy} = elem(@ball_spots, rem(clock, 4))
    rect(x - cam + sx, y + sy, 4, 4, 0x6F9BFF, sprite(acc, @ball, x - cam, y, 20, 1))
  end

  defp hero(acc, %{x: x, y: y, cam: cam, face: face} = s),
    do: sprite(acc, pose(s), x - cam, y, 20, face)

  defp pose(%{phase: :play, ground: true, vx: 0}), do: @stand
  defp pose(%{phase: :play, ground: true, clock: clock}) when rem(clock, 2) == 0, do: @run_a
  defp pose(%{phase: :play, ground: true}), do: @run_b
  defp pose(%{phase: :play, vy: vy}) when vy < 0, do: @run_a
  defp pose(_s), do: @stand

  defp overlay(acc, %{phase: :title}) do
    card(acc, 40, 40, 240, 130, [
      {48, 0xFFFFFF, "SONIC THE HEDGEHOG"},
      {66, @gold, "i VARBERG"},
      {92, 0xFFFFFF, "Left/Right   run  "},
      {108, 0xFFFFFF, "Up/Enter     jump "},
      {124, 0xFFFFFF, "Down         roll "},
      {148, @gold, "Enter to start"}
    ])
  end

  defp overlay(acc, %{phase: :clear, rings: rings, timer: timer, bonus: bonus, score: score} = s) do
    got = number(rings) <> "/" <> number(Sonic.ring_count())
    prompt = if timer == 0, do: [{158, @gold, "Enter to replay"}], else: []

    hud(
      card(acc, 48, 52, 224, 128, [
        {60, 0xFFFFFF, "SONIC GOT THROUGH"},
        # "Ä" is 0x8E in code page 437.
        {80, @gold, <<"TILL F", 0x8E, "STNINGEN">>},
        {104, 0xFFFFFF, "BONUS  " <> pad(bonus)},
        {120, 0xFFFFFF, "SCORE  " <> pad(score)},
        {136, 0xFFFFFF, "RINGS  " <> pad(got)} | prompt
      ]),
      s
    )
  end

  defp overlay(acc, %{phase: :over} = s) do
    hud(
      card(acc, 80, 90, 160, 48, [
        {98, 0xE3262E, "GAME OVER"},
        {118, 0xFFFFFF, "Enter to retry"}
      ]),
      s
    )
  end

  defp overlay(acc, s), do: hud(acc, s)

  defp hud(acc, %{rings: rings, clock: clock, t: t, score: score, lives: lives}) do
    label = if rings == 0 and rem(clock, 4) < 2, do: 0xE3262E, else: @gold
    seconds = div(t, 10)

    [
      text(4, 30, @gold, @hud_bg, "SCORE"),
      text(52, 30, 0xFFFFFF, @hud_bg, number(score)),
      text(116, 30, label, @hud_bg, "RINGS"),
      text(164, 30, 0xFFFFFF, @hud_bg, number(rings)),
      text(204, 30, @gold, @hud_bg, "TIME"),
      text(244, 30, 0xFFFFFF, @hud_bg, clock_face(seconds)),
      text(292, 30, 0xFFFFFF, @hud_bg, "x" <> number(lives))
      | acc
    ]
  end

  # Each line is centred on the panel.
  defp card(acc, x, y, w, h, lines) do
    :lists.foldl(
      fn {ly, colour, body}, acc ->
        [text(div(320 - 8 * byte_size(body), 2), ly, colour, @card, body) | acc]
      end,
      [{:rect, x, y, w, h, @card} | acc],
      lines
    )
  end

  defp text(x, y, colour, bg, body), do: {:text, x, y, :default16px, colour, bg, body}

  defp number(n), do: :erlang.integer_to_binary(n)

  # Pads the value column so card lines centre as one block.
  defp pad(value) when is_integer(value), do: pad(number(value))
  defp pad(value) when byte_size(value) >= 8, do: value
  defp pad(value), do: pad(value <> " ")

  defp clock_face(seconds) do
    number(div(seconds, 60)) <>
      ":" <> number(div(rem(seconds, 60), 10)) <> number(rem(seconds, 10))
  end

  # Draws a packed sprite, mirrored when `facing` is -1 across a box `w` wide.
  defp sprite(acc, <<dx, dy, w, h, c, rest::binary>>, x, y, span, facing) do
    left = if facing == 1, do: x + dx, else: x + span - dx - w
    sprite(rect(left, y + dy, w, h, elem(@palette, c), acc), rest, x, y, span, facing)
  end

  defp sprite(acc, <<>>, _x, _y, _span, _facing), do: acc

  defp rect(x, y, w, h, colour, acc) do
    left = max(x, 0)
    top = max(y, @top)
    right = min(x + w, 320)
    bottom = min(y + h, 240)

    case right > left and bottom > top do
      true -> [{:rect, left, top, right - left, bottom - top, colour} | acc]
      false -> acc
    end
  end
end
