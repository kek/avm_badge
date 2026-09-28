defmodule Badge.SonicTest do
  use ExUnit.Case, async: true

  defp playing do
    {:ok, s} = Badge.Sonic.press(Badge.Sonic.new(), {:edit, :newline})
    s
  end

  defp press(s, event) do
    {:ok, s} = Badge.Sonic.press(s, event)
    s
  end

  defp steps(s, 0), do: s
  defp steps(s, n), do: steps(Badge.Sonic.step(s), n - 1)

  # Holds a key the way the keyboard does: a press, then a repeat every tick or so.
  defp hold(s, event, 0), do: press(s, event) |> Badge.Sonic.step()
  defp hold(s, event, n), do: hold(press(s, event) |> Badge.Sonic.step(), event, n - 1)

  describe "title" do
    test "starts on the title and Enter begins the act" do
      assert Badge.Sonic.new().phase == :title
      assert playing().phase == :play
    end

    test "a direction on the title does nothing" do
      assert Badge.Sonic.press(Badge.Sonic.new(), {:move, :right}) == :ignore
    end

    test "Sonic starts standing on the beach" do
      s = steps(playing(), 3)

      assert s.ground
      assert s.y + elem(Badge.Sonic.size(), 1) == 200
    end
  end

  describe "running" do
    test "holding right speeds up to a top speed" do
      s = hold(playing(), {:move, :right}, 10)

      assert s.vx == 20
      assert s.face == 1
    end

    test "one press keeps running through the keyboard's repeat delay" do
      s = playing() |> press({:move, :right}) |> steps(5)

      assert s.vx > 0
    end

    test "letting go slows to a stop" do
      s = playing() |> hold({:move, :right}, 4) |> steps(20)

      assert s.vx == 0
    end

    test "left from standing faces left and stays in the act" do
      s = playing() |> hold({:move, :left}, 5)

      assert s.face == -1
      assert s.x >= 0
    end

    test "the camera follows" do
      s = hold(playing(), {:move, :right}, 12)

      assert s.cam == Badge.Sonic.camera(s.x)
      assert s.cam > 0
    end
  end

  describe "jumping" do
    test "Up leaves the ground as a ball and lands again" do
      s = playing() |> Badge.Sonic.step() |> press({:move, :up}) |> Badge.Sonic.step()

      assert s.vy < 0
      refute s.ground
      assert s.roll == :air

      landed = steps(s, 20)

      assert landed.ground
      assert landed.roll == :none
    end

    test "Space jumps too" do
      s = playing() |> Badge.Sonic.step() |> press({:char, ?\s}) |> Badge.Sonic.step()

      assert s.vy < 0
    end

    test "down rolls only at speed" do
      assert playing() |> Badge.Sonic.step() |> press({:move, :down}) |> Map.get(:roll) == :none

      fast = hold(playing(), {:move, :right}, 5)

      assert press(fast, {:move, :down}).roll == :ground
    end
  end

  describe "falling" do
    test "the sea is fatal, and a life comes off after the fall" do
      s = %{playing() | x: 660, y: 100, ground: false}
      s = steps(s, 10)

      assert s.phase == :dead

      respawned = steps(s, 25)

      assert respawned.phase == :play
      assert respawned.lives == 2
    end

    test "losing the last life is game over, and Enter starts again" do
      s = %{playing() | x: 660, y: 100, ground: false, lives: 1} |> steps(40)

      assert s.phase == :over
      assert press(steps(s, 10), {:edit, :newline}).phase == :title
    end

    test "a checkpoint that has been passed is where Sonic comes back" do
      [post | _] = Badge.Sonic.checkpoints()
      s = %{playing() | check: post, x: 660, y: 100, ground: false} |> steps(40)

      assert s.x == post
    end
  end

  describe "rings" do
    test "running through rings collects each once" do
      s = hold(playing(), {:move, :right}, 12)

      assert s.rings > 0
      assert length(s.got) == s.rings
    end
  end

  describe "enemies" do
    test "a ball smashes an enemy and scores" do
      [crab | _] = Badge.Sonic.window(0).enemies
      {ex, ey, _w, _h, _f} = Badge.Sonic.enemy_at(crab, 1)

      s = %{playing() | x: ex, y: ey - 10, vy: 5, ground: false, roll: :air}
      s = Badge.Sonic.step(s)

      assert :lists.member(0, s.killed)
      assert s.score == 100
      assert s.vy < 0
    end

    test "walking into one with rings drops the rings" do
      [crab | _] = Badge.Sonic.window(0).enemies
      {ex, _ey, _w, _h, _f} = Badge.Sonic.enemy_at(crab, 1)

      s = %{playing() | x: ex, rings: 5}
      s = Badge.Sonic.step(s)

      assert s.rings == 0
      assert s.hurt > 0
      assert s.phase == :play
    end

    test "walking into one without rings is fatal" do
      [crab | _] = Badge.Sonic.window(0).enemies
      {ex, _ey, _w, _h, _f} = Badge.Sonic.enemy_at(crab, 1)

      assert Badge.Sonic.step(%{playing() | x: ex}).phase == :dead
    end
  end

  describe "the goal" do
    test "reaching the fortress clears the act with a bonus" do
      s = %{playing() | x: Badge.Sonic.goal() - 4, rings: 10, vx: 10}
      s = Badge.Sonic.step(s)

      assert s.phase == :clear
      assert s.bonus >= 1000
      assert s.score == s.bonus
    end

    test "the replay prompt waits a moment" do
      s = Badge.Sonic.step(%{playing() | x: Badge.Sonic.goal() - 4, vx: 10})

      assert Badge.Sonic.press(s, {:edit, :newline}) == :ignore
      assert press(steps(s, 10), {:edit, :newline}).phase == :title
    end
  end

  describe "springs" do
    test "landing on one launches Sonic high" do
      {x, top} = hd(Badge.Sonic.window(3380).springs)

      s = %{playing() | x: x, y: top - 40, vy: 4, ground: false, cam: Badge.Sonic.camera(x)}
      s = Badge.Sonic.step(s)

      assert s.vy < -30
    end
  end

  describe "keys" do
    test "unused keys are ignored in play" do
      assert Badge.Sonic.press(playing(), {:char, ?q}) == :ignore
    end
  end
end
