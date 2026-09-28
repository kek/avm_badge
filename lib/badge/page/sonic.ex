defmodule Badge.Page.Sonic do
  @moduledoc """
  Sonic the Hedgehog, in Varberg: one act from the beach past Kallbadhuset
  to Varbergs fästning.

  Left and Right run, Up, Enter or Space jump, Down rolls. The game is
  `Badge.Sonic.Game`; this page feeds it keys and ticks and draws it with
  `Badge.Sonic.Draw`. Esc is never taken, so the router can always go home.
  """

  use Badge.Page

  alias Badge.Sonic.Draw
  alias Badge.Sonic.Game

  @impl true
  def title, do: "Sonic"

  @impl true
  def icon, do: :diamond

  @impl true
  def init, do: Game.new()

  @impl true
  def render(state), do: Draw.frame(state)

  @impl true
  def handle_key({:nav, _key}, _state), do: :ignore
  def handle_key(event, state), do: Game.press(state, event)

  @impl true
  def tick(state), do: Game.step(state)

  @impl true
  def refresh(%{phase: :play}), do: 100
  def refresh(%{phase: :dead}), do: 100
  def refresh(_state), do: 200
end
