defmodule Mix.Tasks.Nerves.System.Compatibility do
  @shortdoc "Prints Nerves systems compatibility information"

  @moduledoc ~S"""
  Prints Nerves systems compatibility information.

  ## Examples

      # Print the short content to the shell
      mix nerves.system.compatibility

      # Print the long content to the shell
      mix nerves.system.compatibility --verbose

      # Print the content to a file
      mix nerves.system.compatibility --output docs/compatibility.md

   ## Command line options

    * `--verbose`, `-v` - Prints documentation
    * `--output`, `-o` - Output file path

  """

  use Mix.Task

  @switches [
    verbose: :boolean,
    output: :string
  ]

  @aliases [
    v: :verbose,
    o: :output
  ]

  @impl Mix.Task
  def run(args, config \\ Mix.Project.config()) do
    {:ok, _} = Application.ensure_all_started(config[:app])

    {cli_opts, _, _} = OptionParser.parse(args, aliases: @aliases, switches: @switches)

    content =
      cond do
        cli_opts[:verbose] -> build_doc()
        true -> build_table()
      end

    if output = cli_opts[:output] do
      File.write!(output, content)
      Mix.shell().info("Wrote content to #{output}")
    else
      Mix.shell().info(content)
    end
  end

  defp build_doc do
    """
    The Nerves System (`nerves_system_*`) dependency determines the OTP version
    running on the target. It is possible that a recent update to the Nerves
    System pulled in a new version of Erlang/OTP. If you are using an official
    Nerves System, you can verify this by reviewing the chart below or
    `CHANGELOG.md` file that comes with the release.

    #{build_table()}

    Run `mix deps` to see the Nerves System version and go to that system's
    repository on https://github.com/nerves-project.

    If you need to run a particular version of Erlang/OTP on your target, you can
    either lock the `nerves_system_*` dependency in your `mix.exs` to an older
    version. Note that this route prevents you from receiving security updates
    from the official systems. The other option is to build a custom Nerves
    system. See the Nerves documentation for building a custom system and then
    run `make menuconfig` and look for the Erlang options.
    """
  end

  defp build_table do
    NervesSystemsCompatibility.get_data()
    |> NervesSystemsCompatibility.build_table()
  end
end
