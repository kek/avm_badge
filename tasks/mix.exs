defmodule BadgeTasks.MixProject do
  use Mix.Project

  # The firmware's own Mix tasks. A dependency with `runtime: false`, so
  # ExAtomVM leaves them out of main.avm; they only ever run on the host.
  def project do
    [
      app: :badge_tasks,
      version: "0.1.0",
      elixir: "~> 1.13",
      deps: []
    ]
  end
end
