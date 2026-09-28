defmodule Mix.Tasks.Badge.Assets do
  @shortdoc "Packs assets.avm from the frames, fonts, logo and games the device reads at runtime"

  @moduledoc """
  Writes `assets.avm` at the repo root, ready for `tools/flashassets.sh`.

  Modules under `games/` are compiled and packed here rather than into
  `main.avm`; the VM loads them from this partition once `Badge.start/0` has
  mounted it.

      mix badge.assets
  """

  use Mix.Task

  @out "assets.avm"

  @impl Mix.Task
  def run(_args) do
    stage = Path.join(System.tmp_dir!(), "badge-assets-#{System.unique_integer([:positive])}")
    rickroll = Path.join(stage, "assets/priv/rickroll")
    fonts = Path.join(stage, "assets/priv/fonts")
    logo = Path.join(stage, "assets/priv/logo")
    ebin = Path.join(stage, "ebin")

    try do
      File.mkdir_p!(rickroll)
      File.mkdir_p!(fonts)
      File.mkdir_p!(logo)
      frames = Path.wildcard("assets/rickroll/*.rgba")
      uf_fonts = Path.wildcard("assets/fonts/*.uf")
      logos = Path.wildcard("assets/logo/*.rgba")
      if frames == [], do: Mix.raise("no frames found in assets/rickroll")
      if uf_fonts == [], do: Mix.raise("no fonts found in assets/fonts")
      if logos == [], do: Mix.raise("no logo found in assets/logo")
      copy(frames, rickroll)
      copy(uf_fonts, fonts)
      copy(logos, logo)
      beams = compile_games(ebin)

      out = Path.expand(@out)
      # Names inside the archive are relative to the staging directory.
      File.cd!(stage, fn ->
        inputs =
          (Path.wildcard("assets/priv/rickroll/*.rgba") ++
             Path.wildcard("assets/priv/fonts/*.uf") ++
             Path.wildcard("assets/priv/logo/*.rgba") ++ beams)
          |> Enum.map(&to_charlist/1)

        :ok = :packbeam_api.create(to_charlist(out), inputs, %{lib: true})
      end)

      Mix.shell().info("#{@out}: #{File.stat!(out).size} bytes")
    after
      File.rm_rf!(stage)
    end
  end

  # Compiled against the firmware in lib/, which has to be built first.
  defp compile_games(ebin) do
    Mix.Task.run("compile")
    File.mkdir_p!(ebin)

    case Path.wildcard("games/**/*.ex") do
      [] ->
        []

      sources ->
        {:ok, _modules, _diagnostics} =
          Kernel.ParallelCompiler.compile_to_path(sources, ebin, return_diagnostics: true)

        for beam <- File.ls!(ebin), do: Path.join("ebin", beam)
    end
  end

  defp copy(paths, dest) do
    for path <- paths, do: File.cp!(path, Path.join(dest, Path.basename(path)))
  end
end
