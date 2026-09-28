defmodule Badge.Page.SonicTest do
  use ExUnit.Case, async: true

  alias Badge.Page.Sonic
  alias Badge.Sonic.Game
  alias Badge.Sonic.Level

  defp play_from(x) do
    {:ok, s} = Sonic.handle_key({:edit, :newline}, Sonic.init())
    %{s | x: x, cam: Game.camera(x)}
  end

  defp states do
    title = Sonic.init()
    over = %{play_from(40) | phase: :over}
    clear = %{play_from(Level.goal()) | phase: :clear, bonus: 3000}

    [title, over, clear] ++
      for x <- 0..Level.width()//160, do: Sonic.tick(play_from(x))
  end

  test "Esc and the shape keys are left to the router" do
    assert Sonic.handle_key({:nav, :home}, Sonic.init()) == :ignore
    assert Sonic.handle_key({:nav, :circle}, play_from(40)) == :ignore
  end

  test "plays at ten frames a second and idles slower" do
    assert Sonic.refresh(play_from(40)) == 100
    assert Sonic.refresh(Sonic.init()) == 200
  end

  test "every rect stays on the panel below the title bar" do
    for s <- states(), {:rect, x, y, w, h, _c} <- Sonic.render(s) do
      assert x >= 0 and y >= 26 and w > 0 and h > 0
      assert x + w <= 320 and y + h <= 240
    end
  end

  test "text sits on the panel" do
    for s <- states(), {:text, x, y, _font, _fg, _bg, body} <- Sonic.render(s) do
      assert x >= 0 and y >= 26
      assert x + 8 * byte_size(body) <= 320
    end
  end

  test "a frame stays small enough to draw ten times a second" do
    for s <- states() do
      assert length(Sonic.render(s)) < 200
    end
  end
end
