defmodule Badge.Page.Sonic do
  @moduledoc """
  Sonic the Hedgehog, in Varberg: one act from the beach past Kallbadhuset
  to Varbergs fästning.

  Left and Right run, Up, Enter or Space jump, Down rolls. The game is
  `Badge.Sonic.Game`; this page feeds it keys and ticks and draws it with
  `Badge.Sonic.Draw`. Esc is never taken, so the router can always go home.

  The game lives in the assets partition, not in this image. Without it, or
  with assets flashed before the game existed, the page says so instead.
  """

  use Badge.Page

  alias Badge.Sonic.Draw
  alias Badge.Sonic.Game
  alias Badge.Theme

  @compile {:no_warn_undefined, [Badge.Sonic.Game, Badge.Sonic.Draw]}

  @impl true
  def title, do: "Sonic"

  @impl true
  def icon, do: :diamond

  @impl true
  def init do
    Game.new()
  catch
    :error, :undef -> %{phase: :missing}
  end

  @impl true
  def render(%{phase: :missing}) do
    [
      {:text, 8, 100, :default16px, Theme.fg(), Theme.bg(), "The game is in the assets"},
      {:text, 8, 120, :default16px, Theme.fg(), Theme.bg(), "partition. Flash it with"},
      {:text, 8, 140, :default16px, Theme.accent(), Theme.bg(), "tools/flashassets.sh"}
    ]
  end

  def render(state), do: Draw.frame(state)

  @impl true
  def handle_key({:nav, _key}, _state), do: :ignore
  def handle_key(_event, %{phase: :missing}), do: :ignore
  def handle_key(event, state), do: Game.press(state, event)

  @impl true
  def tick(%{phase: :missing} = state), do: state
  def tick(state), do: Game.step(state)

  @impl true
  def refresh(%{phase: :play}), do: 100
  def refresh(%{phase: :dead}), do: 100
  def refresh(%{phase: :missing}), do: 1000
  def refresh(_state), do: 200
end
