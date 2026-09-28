defmodule Badge.Sonic.Game do
  @moduledoc """
  Sonic in Varberg as plain data: `new/0` for the title, `press/2` for a key,
  `step/1` once per 100 ms tick.

  The keyboard reports presses, never releases, so a direction key counts as
  held for `@hold` ticks after its last press or repeat. That outlasts the
  keyboard's 500 ms repeat delay, so holding a key runs without a stutter.

  Phases: `:title`, `:play`, `:dead` while Sonic falls off the panel,
  `:clear` past the goal and `:over` with no lives left.
  """

  alias Badge.Sonic.Level

  @w 20
  @h 26

  @hold 6
  @accel 4
  @brake 8
  @max_run 20
  @friction 3
  @roll_friction 1
  @gravity 5
  @max_fall 22
  @jump -27
  @bounce -20
  @spring -34
  @knockback -18
  @hurt_ticks 20
  @dead_ticks 20
  @lives 3
  @view 320
  @lead 140
  @floor 240

  @doc "Sonic's box, `{w, h}`."
  def size, do: {@w, @h}

  @doc "The title screen."
  def new, do: %{fresh(@lives, 0, elem(Level.start(), 0)) | phase: :title}

  defp fresh(lives, score, from) do
    {_x, y} = Level.start()

    %{
      phase: :play,
      clock: 0,
      t: 0,
      timer: 0,
      x: from,
      y: y,
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
      check: from,
      got: [],
      killed: [],
      bonus: 0,
      cam: camera(from)
    }
  end

  @doc "Applies a key event, or `:ignore` for one the game has no use for."
  def press(%{phase: :play} = s, {:move, :right}), do: {:ok, %{s | run: @hold, dir: 1}}
  def press(%{phase: :play} = s, {:move, :left}), do: {:ok, %{s | run: @hold, dir: -1}}

  def press(%{phase: :play, ground: true, roll: :none, vx: vx} = s, {:move, :down})
      when vx >= 6 or vx <= -6,
      do: {:ok, %{s | roll: :ground}}

  def press(%{phase: :play} = s, {:move, :down}), do: {:ok, s}

  def press(s, event) do
    case jump_key?(event) do
      true -> jump(s)
      false -> :ignore
    end
  end

  defp jump(%{phase: :play} = s), do: {:ok, %{s | jump: 2}}
  defp jump(%{phase: :title}), do: {:ok, fresh(@lives, 0, elem(Level.start(), 0))}

  defp jump(%{phase: phase, timer: 0}) when phase == :clear or phase == :over,
    do: {:ok, new()}

  defp jump(_s), do: :ignore

  defp jump_key?({:move, :up}), do: true
  defp jump_key?({:edit, :newline}), do: true
  defp jump_key?({:char, ?\s}), do: true
  defp jump_key?(_event), do: false

  @doc "Advances one tick."
  def step(%{phase: :play} = s) do
    window = Level.window(s.cam)

    s = %{s | clock: s.clock + 1, t: s.t + 1}

    s
    |> steer()
    |> move_x(window)
    |> move_y(window)
    |> collect(window)
    |> fight(window)
    |> progress()
  end

  def step(%{phase: :dead} = s) do
    s = %{s | clock: s.clock + 1, y: s.y + s.vy, vy: min(s.vy + @gravity, @max_fall)}

    case s.timer do
      0 -> respawn(s)
      n -> %{s | timer: n - 1}
    end
  end

  def step(s), do: %{s | clock: s.clock + 1, timer: max(s.timer - 1, 0)}

  defp respawn(%{lives: 1} = s), do: %{s | phase: :over, lives: 0, timer: 10}
  defp respawn(s), do: %{fresh(s.lives - 1, s.score, s.check) | clock: s.clock}

  defp steer(s) do
    vx = run(s)

    s = %{
      s
      | vx: vx,
        face: face(s),
        run: max(s.run - 1, 0),
        hurt: max(s.hurt - 1, 0),
        vy: min(s.vy + @gravity, @max_fall),
        roll: unroll(s.roll, vx)
    }

    case s.jump > 0 and s.ground do
      true -> %{s | vy: @jump, ground: false, roll: :air, jump: 0}
      false -> %{s | jump: max(s.jump - 1, 0)}
    end
  end

  defp run(%{roll: :ground, vx: vx}), do: toward_zero(vx, @roll_friction)

  defp run(%{run: run, dir: dir, vx: vx}) when run > 0 and dir * vx < 0,
    do: vx + dir * @brake

  defp run(%{run: run, dir: dir, vx: vx}) when run > 0,
    do: max(min(vx + dir * @accel, @max_run), -@max_run)

  defp run(%{ground: true, vx: vx}), do: toward_zero(vx, @friction)
  defp run(%{vx: vx}), do: vx

  defp face(%{run: run, dir: dir}) when run > 0, do: dir
  defp face(%{face: face}), do: face

  defp unroll(:ground, 0), do: :none
  defp unroll(roll, _vx), do: roll

  defp toward_zero(v, by) when v > by, do: v - by
  defp toward_zero(v, by) when v < -by, do: v + by
  defp toward_zero(_v, _by), do: 0

  defp move_x(s, window) do
    x = max(min(s.x + s.vx, Level.width() - @w), 0)

    case wall(window.ground, s, x) do
      nil -> %{s | x: x}
      edge -> %{s | x: edge, vx: 0}
    end
  end

  defp wall([], _s, _x), do: nil

  defp wall([{bx, top, bw, _kind} | rest], s, x) do
    case s.y + @h > top and x < bx + bw and x + @w > bx do
      true when s.vx > 0 -> bx - @w
      true when s.vx < 0 -> bx + bw
      _clear -> wall(rest, s, x)
    end
  end

  # Only a fall can land; a rise passes through everything.
  defp move_y(%{vy: vy} = s, _window) when vy < 0, do: %{s | y: s.y + vy, ground: false}

  defp move_y(s, window) do
    y = s.y + s.vy

    case landing(s, y, window) do
      nil ->
        %{s | y: y, ground: false}

      {top, :spring} ->
        %{s | y: top - @h, vy: @spring, ground: false, roll: :none}

      {top, :solid} ->
        %{s | y: top - @h, vy: 0, ground: true, roll: landed(s.roll)}
    end
  end

  defp landed(:air), do: :none
  defp landed(roll), do: roll

  defp landing(s, y, window) do
    surfaces =
      for({x, top, w, _kind} <- window.ground, do: {x, top, w, :solid}) ++
        for({x, top, w} <- window.platforms, do: {x, top, w, :solid}) ++
        for {x, top} <- window.springs, do: {x, top - 8, 20, :spring}

    highest(surfaces, s, y, nil)
  end

  defp highest([], _s, _y, best), do: best

  defp highest([{x, top, w, kind} | rest], s, y, best) do
    lands = s.x < x + w and s.x + @w > x and s.y + @h <= top and y + @h >= top

    case lands and (best == nil or top < elem(best, 0)) do
      true -> highest(rest, s, y, {top, kind})
      false -> highest(rest, s, y, best)
    end
  end

  defp collect(s, window) do
    caught =
      for {id, rx, ry} <- window.rings,
          not :lists.member(id, s.got),
          overlap?(s.x, s.y, @w, @h, rx - 6, ry - 6, 12, 12),
          do: id

    %{s | got: caught ++ s.got, rings: s.rings + length(caught)}
  end

  defp fight(s, window) do
    hits =
      for {id, _kind, _x0, _x1, _y} = enemy <- window.enemies,
          not :lists.member(id, s.killed),
          hit = touch(s, id, Level.enemy_at(enemy, s.clock)),
          do: hit

    clash(hits, s)
  end

  defp touch(s, id, {ex, ey, ew, eh, _facing}) do
    case overlap?(s.x, s.y, @w, @h, ex, ey, ew, eh) do
      true -> {id, ey, eh}
      false -> nil
    end
  end

  defp clash([], s), do: s

  defp clash([{id, ey, eh} | rest], s) do
    case attacking?(s, ey, eh) do
      true -> clash(rest, smash(s, id))
      false -> clash(rest, hurt(s))
    end
  end

  # A ball or a stomp from above wins; anything else is a hit.
  defp attacking?(%{roll: roll}, _ey, _eh) when roll != :none, do: true
  defp attacking?(s, ey, eh), do: s.vy > 0 and s.y + @h - s.vy <= ey + div(eh, 2)

  defp smash(s, id) do
    s = %{s | killed: [id | s.killed], score: s.score + 100}

    case s.ground do
      true -> s
      false -> %{s | vy: @bounce, roll: :air}
    end
  end

  defp hurt(%{hurt: hurt} = s) when hurt > 0, do: s
  defp hurt(%{rings: 0} = s), do: die(s)

  defp hurt(s) do
    %{
      s
      | rings: 0,
        hurt: @hurt_ticks,
        vy: @knockback,
        vx: -s.face * 8,
        ground: false,
        roll: :none,
        run: 0
    }
  end

  defp die(s), do: %{s | phase: :dead, timer: @dead_ticks, vy: -24, vx: 0, roll: :none}

  defp progress(%{y: y} = s) when y > @floor, do: die(s)

  defp progress(%{x: x} = s) do
    case x >= Level.goal() do
      true -> clear(s)
      false -> %{s | check: checkpoint(x, s.check), cam: camera(x)}
    end
  end

  defp clear(s) do
    seconds = div(s.t, 10)
    bonus = s.rings * 100 + max(300 - seconds, 0) * 10

    %{s | phase: :clear, timer: 10, bonus: bonus, score: s.score + bonus, vx: 0, run: 0}
  end

  defp checkpoint(x, check) do
    :lists.foldl(
      fn post, acc ->
        case x >= post and post > acc do
          true -> post
          false -> acc
        end
      end,
      check,
      Level.checkpoints()
    )
  end

  @doc "The camera's left edge for Sonic at `x`."
  def camera(x), do: max(min(x + div(@w, 2) - @lead, Level.width() - @view), 0)

  defp overlap?(ax, ay, aw, ah, bx, by, bw, bh) do
    ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
  end
end
