defmodule Mix.Tasks.Badge.Fit do
  @shortdoc "Fails if the packed firmware is larger than its flash slot"

  @moduledoc """
  Checks the packed `avm_badge.avm` against the `main.avm` slot.

      mix badge.fit

  Runs inside `mix atomvm.esp32.flash`, before anything is written. An archive
  that outgrows the slot is cut off at its end, and the VM then crashes while
  loading it, before any Elixir runs. `alt.avm` is the same size.
  """

  use Mix.Task

  @slot 0xA4000

  @impl Mix.Task
  def run(_args) do
    avm = "#{Mix.Project.config()[:app]}.avm"

    case File.stat(avm) do
      {:ok, %{size: size}} when size > @slot ->
        Mix.raise("#{avm} is #{size} bytes, #{size - @slot} over the #{@slot}-byte main.avm slot")

      {:ok, %{size: size}} ->
        Mix.shell().info("#{avm}: #{size} of #{@slot} bytes, #{@slot - size} free")

      {:error, reason} ->
        Mix.raise("cannot read #{avm}: #{:file.format_error(reason)}; run mix atomvm.packbeam")
    end
  end
end
