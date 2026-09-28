defmodule Badge.Sonic do
  @moduledoc """
  Sonic in Varberg as plain data: `new/0` for the title, `press/2` for a key,
  `step/1` once per 100 ms tick. `Badge.Page.Sonic` draws it.

  The keyboard reports presses, never releases, so a direction counts as held
  for `@hold` ticks after its last press or repeat; that outlasts the 500 ms
  repeat delay. Phases: `:title`, `:play`, `:dead` while Sonic falls off the
  panel, `:clear` past the goal and `:over` with no lives left.

  The act runs from the beach past Kallbadhuset's pier and the rocks to
  Varbergs fästning. World y is panel y, since it never scrolls vertically.
  """

  @w 20
  @h 26
  @width 4040
  @goal 3900
  @checkpoints [1600, 3060]
  @view 320

  @hold 6
  @gravity 5
  @max_fall 22
  @max_run 20

  # {x, top, w, kind}, solid to the bottom of the panel; walls last so they draw over the grass.
  @ground [
    {0, 200, 640, :sand},
    {1540, 200, 360, :rock},
    {1900, 176, 200, :rock},
    {2100, 152, 220, :rock},
    {2320, 200, 700, :grass},
    {3020, 200, 1020, :grass},
    {3200, 168, 120, :wall},
    {3440, 144, 100, :wall}
  ]

  # {x, y, w}, landed on from above only.
  @piers [
    {720, 190, 160},
    {940, 176, 140},
    {1140, 160, 120},
    {1320, 176, 170},
    {2340, 70, 160},
    {2560, 90, 140},
    {2760, 110, 160}
  ]

  @springs [{2270, 152}, {3380, 200}]

  # Rows of rings, {x, y, count, gap, sag}; a sag bends the row into an arc.
  @rows for {row, i} <-
              Enum.with_index([
                {220, 178, 6, 28, 0},
                {646, 150, 5, 18, 5},
                {760, 164, 4, 28, 0},
                {886, 140, 4, 18, 5},
                {975, 150, 4, 28, 0},
                {1090, 128, 4, 16, 5},
                {1170, 134, 3, 28, 0},
                {1350, 150, 5, 28, 0},
                {1700, 178, 5, 28, 0},
                {1950, 154, 4, 28, 0},
                {2380, 48, 5, 26, 0},
                {2590, 68, 4, 28, 0},
                {2790, 88, 5, 28, 0},
                {3100, 178, 4, 28, 0},
                {3330, 130, 5, 20, 5},
                {3600, 178, 6, 28, 0}
              ]),
            do: Tuple.insert_at(row, 0, i * 8)

  @ring_count Enum.sum(for {_, _, _, n, _, _} <- @rows, do: n)

  # {id, kind, x0, x1, y}, patrolling between x0 and x1.
  @enemies for {e, i} <-
                 Enum.with_index([
                   {:crab, 420, 600, 186},
                   {:gull, 880, 1080, 120},
                   {:gull, 1180, 1380, 104},
                   {:crab, 1620, 1860, 186},
                   {:crab, 2140, 2240, 138},
                   {:goat, 2420, 2620, 178},
                   {:gull, 2700, 2900, 60},
                   {:goat, 3060, 3180, 178},
                   {:crab, 3560, 3760, 186},
                   {:gull, 3620, 3820, 110}
                 ]),
               do: Tuple.insert_at(e, 0, i)

  def size, do: {@w, @h}
  def goal, do: @goal
  def checkpoints, do: @checkpoints
  def ring_count, do: @ring_count

  @doc "The title screen."
  def new, do: %{fresh(3, 0, 40) | phase: :title}

  defp fresh(lives, score, x) do
    %{
      phase: :play,
      clock: 0,
      t: 0,
      timer: 0,
      x: x,
      y: 200 - @h,
      vx: 0,
      vy: 0,
      ground: true,
      face: 1,
      run: 0,
      dir: 1,
      jump: 0,
      roll: :none,
      hurt: 0,
      rings: 0,
      score: score,
      lives: lives,
      check: x,
      got: [],
      killed: [],
      bonus: 0,
      cam: camera(x)
    }
  end

  # Fields are matched in heads: every `s.field` compiles to a fallback branch.

  @doc "Applies a key event, or `:ignore` for one the game has no use for."
  def press(%{phase: :play} = s, {:move, :right}), do: {:ok, %{s | run: @hold, dir: 1}}
  def press(%{phase: :play} = s, {:move, :left}), do: {:ok, %{s | run: @hold, dir: -1}}

  def press(%{phase: :play, ground: true, roll: :none, vx: vx} = s, {:move, :down})
      when vx >= 6 or vx <= -6,
      do: {:ok, %{s | roll: :ground}}

  def press(%{phase: :play} = s, {:move, :down}), do: {:ok, s}
  def press(s, {:move, :up}), do: jump(s)
  def press(s, {:edit, :newline}), do: jump(s)
  def press(s, {:char, ?\s}), do: jump(s)
  def press(_s, _event), do: :ignore

  defp jump(%{phase: :play} = s), do: {:ok, %{s | jump: 2}}
  defp jump(%{phase: :title}), do: {:ok, fresh(3, 0, 40)}
  defp jump(%{phase: p, timer: 0}) when p == :clear or p == :over, do: {:ok, new()}
  defp jump(_s), do: :ignore

  @doc "Advances one tick."
  def step(%{phase: :play, cam: cam} = s) do
    %{ground: ground, rings: rings, enemies: enemies} = near = window(cam)

    s
    |> steer()
    |> move_x(ground)
    |> move_y(near)
    |> collect(rings)
    |> fight(enemies)
    |> progress()
  end

  def step(%{phase: :dead, timer: 0, lives: 1} = s), do: %{s | phase: :over, lives: 0, timer: 10}

  def step(%{phase: :dead, timer: 0, lives: lives, score: score, check: check, clock: clock}),
    do: %{fresh(lives - 1, score, check) | clock: clock}

  def step(%{phase: :dead, clock: clock, timer: timer, y: y, vy: vy} = s),
    do: %{s | clock: clock + 1, timer: timer - 1, y: y + vy, vy: vy + @gravity}

  def step(%{clock: clock, timer: timer} = s),
    do: %{s | clock: clock + 1, timer: max(timer - 1, 0)}

  defp steer(s) do
    %{roll: roll, run: run, dir: dir, vx: vx, ground: ground, face: face} = s
    %{clock: clock, t: t, hurt: hurt, vy: vy, jump: jump} = s

    vx =
      cond do
        roll == :ground -> toward_zero(vx, 1)
        run > 0 and dir * vx < 0 -> vx + dir * 8
        run > 0 -> max(min(vx + dir * 4, @max_run), -@max_run)
        ground -> toward_zero(vx, 3)
        true -> vx
      end

    s = %{
      s
      | clock: clock + 1,
        t: t + 1,
        vx: vx,
        face: if(run > 0, do: dir, else: face),
        roll: if(roll == :ground and vx == 0, do: :none, else: roll),
        run: max(run - 1, 0),
        hurt: max(hurt - 1, 0),
        vy: min(vy + @gravity, @max_fall),
        jump: max(jump - 1, 0)
    }

    case jump > 0 and ground do
      true -> %{s | vy: -27, ground: false, roll: :air, jump: 0}
      false -> s
    end
  end

  defp toward_zero(v, by) when v > by, do: v - by
  defp toward_zero(v, by) when v < -by, do: v + by
  defp toward_zero(_v, _by), do: 0

  defp move_x(%{x: x0, y: y, vx: vx} = s, ground) do
    x = max(min(x0 + vx, @width - @w), 0)

    blocked =
      for {bx, top, bw, _} <- ground, y + @h > top, x < bx + bw, x + @w > bx do
        if vx > 0, do: bx - @w, else: bx + bw
      end

    case blocked do
      [edge | _] when vx != 0 -> %{s | x: edge, vx: 0}
      _clear -> %{s | x: x}
    end
  end

  # Only a fall can land; a rise passes through everything.
  defp move_y(%{y: y, vy: vy} = s, _near) when vy < 0, do: %{s | y: y + vy, ground: false}

  defp move_y(%{x: sx, y: y0, vy: vy, roll: roll} = s, near) do
    %{ground: ground, piers: piers, springs: springs} = near
    y = y0 + vy

    surfaces =
      for({x, top, w, _} <- ground, do: {x, top, w, 0}) ++
        for({x, top, w} <- piers, do: {x, top, w, 0}) ++
        for {x, top} <- springs, do: {x, top - 8, 20, -34}

    landed =
      for {x, top, w, launch} <- surfaces,
          sx < x + w and sx + @w > x and y0 + @h <= top and y + @h >= top,
          do: {top, launch}

    case :lists.sort(landed) do
      [] -> %{s | y: y, ground: false}
      [{top, 0} | _] -> %{s | y: top - @h, vy: 0, ground: true, roll: landed(roll)}
      [{top, launch} | _] -> %{s | y: top - @h, vy: launch, ground: false, roll: :none}
    end
  end

  defp landed(:air), do: :none
  defp landed(roll), do: roll

  defp collect(%{x: x, y: y, got: got, rings: count} = s, rings) do
    caught =
      for {id, rx, ry} <- rings,
          not :lists.member(id, got),
          overlap?(x, y, rx - 6, ry - 6, 12, 12),
          do: id

    %{s | got: caught ++ got, rings: count + length(caught)}
  end

  defp fight(s, enemies), do: :lists.foldl(&clash/2, s, enemies)

  defp clash({id, _, _, _, _} = enemy, %{clock: clock, x: x, y: y, vy: vy} = s) do
    %{roll: roll, hurt: hurt, rings: rings, killed: killed} = s
    {ex, ey, ew, eh, _facing} = enemy_at(enemy, clock)

    cond do
      :lists.member(id, killed) or not overlap?(x, y, ex, ey, ew, eh) -> s
      roll != :none or (vy > 0 and y + @h - vy <= ey + div(eh, 2)) -> smash(s, id)
      hurt > 0 -> s
      rings > 0 -> hurt(s)
      true -> die(s)
    end
  end

  defp smash(%{killed: killed, score: score, ground: ground} = s, id) do
    s = %{s | killed: [id | killed], score: score + 100}
    if ground, do: s, else: %{s | vy: -20, roll: :air}
  end

  defp hurt(%{face: face} = s) do
    %{s | rings: 0, hurt: 20, vy: -18, vx: -face * 8, ground: false, roll: :none, run: 0}
  end

  defp die(s), do: %{s | phase: :dead, timer: 20, vy: -24, vx: 0, roll: :none}

  defp progress(%{phase: :dead} = s), do: s
  defp progress(%{y: y} = s) when y > 240, do: die(s)

  defp progress(%{x: x, rings: rings, t: t, score: score} = s) when x >= @goal do
    bonus = rings * 100 + max(300 - div(t, 10), 0) * 10
    %{s | phase: :clear, timer: 10, bonus: bonus, score: score + bonus, vx: 0, run: 0}
  end

  defp progress(%{x: x, check: check} = s) do
    passed = for post <- @checkpoints, x >= post, do: post
    %{s | check: :lists.foldl(&max/2, check, passed), cam: camera(x)}
  end

  @doc "The camera's left edge for Sonic at `x`."
  def camera(x), do: max(min(x + div(@w, 2) - 140, @width - @view), 0)

  @doc "The level within about a panel of the camera."
  def window(cam) do
    lo = cam - 340
    hi = cam + 660

    %{
      ground: for({x, _, w, _} = g <- @ground, x < hi and x + w > lo, do: g),
      piers: for({x, _, w} = p <- @piers, x < hi and x + w > lo, do: p),
      springs: for({x, _} = p <- @springs, x < hi and x > lo, do: p),
      rings:
        for(
          {id, x, y, n, gap, sag} <- @rows,
          x < hi and x + n * gap > lo,
          i <- :lists.seq(0, n - 1),
          do: {id + i, x + i * gap, y + div(sag * (2 * i - n + 1) * (2 * i - n + 1), 4)}
        ),
      enemies: for({_, _, x0, x1, _} = e <- @enemies, x0 < hi and x1 > lo, do: e)
    }
  end

  @doc "An enemy's box and heading at `clock`: `{x, y, w, h, facing}`."
  def enemy_at({_id, kind, x0, x1, y}, clock) do
    span = x1 - x0
    travel = rem(clock * speed(kind), 2 * span)
    {w, h} = enemy_size(kind)

    case travel < span do
      true -> {x0 + travel, y + bob(kind, clock), w, h, 1}
      false -> {x0 + 2 * span - travel, y + bob(kind, clock), w, h, -1}
    end
  end

  defp enemy_size(:crab), do: {22, 14}
  defp enemy_size(:gull), do: {26, 14}
  defp enemy_size(:goat), do: {26, 22}

  defp speed(:crab), do: 3
  defp speed(:gull), do: 5
  defp speed(:goat), do: 7

  defp bob(:gull, clock), do: rem(clock, 4) * 2 - 3
  defp bob(_kind, _clock), do: 0

  defp overlap?(x, y, bx, by, bw, bh),
    do: x < bx + bw and x + @w > bx and y < by + bh and y + @h > by
end
