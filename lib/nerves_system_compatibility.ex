defmodule NervesSystemCompatibility do
  @moduledoc """
  Documentation for `NervesSystemCompatibility`.
  """

  @nerves_targets ~w[
    bbb
    osd32mp1
    rpi
    rpi0
    rpi2
    rpi3
    rpi3a
    rpi4
    x86_64
    grisp2
  ]a

  alias NervesSystemCompatibility.Database
  alias NervesSystemCompatibility.Repo
  alias NervesSystemCompatibility.Utils

  @spec nerves_targets :: [atom]
  def nerves_targets, do: @nerves_targets

  @column_labels ["", "Nerves System BR", "Erlang/OTP", "Buildroot", "Linux"]
  @row_opts [column_width: 20]

  def build_chart(opts \\ []) do
    chart_dir = opts[:chart_dir] || "tmp/nerves_system_compatibility"
    chart_format = opts[:format] || :markdown

    chart =
      for target <- @nerves_targets do
        build_chart_for_target(target, opts)
      end
      |> Enum.join("\n\n")

    File.mkdir_p(chart_dir)
    file = "#{chart_dir}/nerves_system_compatibility_#{System.os_time(:second)}.#{chart_format}"
    IO.puts("writing the Nerves system compatibility information to #{file}")
    File.write!(file, chart)
  end

  def build_chart_for_target(target, opts \\ []) do
    Database.open()

    header = [
      Utils.table_row([target | tl(@column_labels)], @row_opts),
      Utils.divider_row(length(@column_labels), @row_opts)
    ]

    data_rows =
      for version <- Database.get({target, :versions}) do
        data = get_data_for_target(target, version)

        values = [
          version,
          data.nerves_system_br_version,
          data.otp_version,
          data.buildroot_version,
          data.linux_version
        ]

        Utils.table_row(values, @row_opts)
      end

    markdown_chart = (header ++ data_rows) |> Enum.join("\n")

    case opts[:format] do
      :html ->
        "<details><summary>nerves_system_#{target}</summary>#{markdown_chart_to_html(markdown_chart)}</details>"

      _ ->
        markdown_chart
    end
  end

  defp markdown_chart_to_html(markdown_chart) do
    markdown_chart
    |> Earmark.as_html!()
    |> String.replace(~r/ style="text-align: left;"/, "")
    |> String.replace(~r/>\s+/, ">")
    |> String.replace(~r/\s+</, "<")
  end

  @doc """
  Returns compatibility data for Nerves Systems.
  """
  @spec get_data :: [%{atom => String.t()}]
  def get_data do
    Database.open()

    for target <- @nerves_targets,
        version <- Database.get({target, :versions}) do
      get_data_for_target(target, version)
    end
  end

  defp get_data_for_target(target, version) do
    nerves_system_br_version = Database.get({target, version, :nerves_system_br_version})

    %{
      target: target,
      version: version,
      nerves_system_br_version: nerves_system_br_version,
      linux_version: Database.get({target, version, :linux_version}),
      buildroot_version: Database.get({:br, nerves_system_br_version, :buildroot_version}),
      otp_version: Database.get({:br, nerves_system_br_version, :otp_version})
    }
  end

  def build_database! do
    Database.open()
    Repo.download_nerves_system_repos()

    nerves_system_br_versions = Repo.get_nerves_system_br_versions()
    Database.put({:br, :versions}, nerves_system_br_versions)

    # Make sure database is accessed sequentially (do not use async tasks)
    for target <- @nerves_targets do
      versions = Repo.get_nerves_system_versions(target)
      Database.put({target, :versions}, versions)

      for version <- versions do
        Database.put(
          {target, version, :nerves_system_br_version},
          Repo.get_nerves_system_br_versions_for_target(target, version)
        )

        Database.put(
          {target, version, :linux_version},
          Repo.get_linux_version_for_target(target, version)
        )

        IO.write(".")
      end
    end

    for nerves_system_br_version <- nerves_system_br_versions do
      Database.put(
        {:br, nerves_system_br_version, :buildroot_version},
        Repo.get_buildroot_version(nerves_system_br_version)
      )

      Database.put(
        {:br, nerves_system_br_version, :otp_version},
        Repo.get_otp_version(nerves_system_br_version)
      )

      IO.write(".")
    end

    IO.write("\n")
    :ok
  end
end
