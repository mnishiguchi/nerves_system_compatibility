defmodule NervesSystemCompatibility do
  @moduledoc """
  Documentation for `NervesSystemCompatibility`.
  """

  alias NervesSystemCompatibility.{Chart, Database, Repo}

  @nerves_targets [:bbb, :rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4, :osd32mp1, :x86_64, :grisp2]

  def nerves_targets, do: @nerves_targets

  def run do
    format =
      case OptionParser.parse!(System.argv(), strict: [format: :string]) do
        {[format: format], _} -> String.to_existing_atom(format)
        _ -> :md
      end

    IO.puts("format: #{format}")

    IO.puts("===> Downloading repos")
    Repo.download_nerves_system_repos()

    IO.puts("===> Building database")
    Database.init()
    Database.build()

    IO.puts("===> Building chart")
    Chart.build(format: format)

    IO.puts("done")
  end
end
