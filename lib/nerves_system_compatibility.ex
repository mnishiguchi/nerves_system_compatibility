defmodule NervesSystemCompatibility do
  @moduledoc """
  Documentation for `NervesSystemCompatibility`.
  """

  @targets ~w[
    bbb
    osd32mp1
    rpi
    rpi0
    rpi2
    rpi3
    rpi3a
    rpi4
    x86_64
  ]a

  alias NervesSystemCompatibility.Database
  alias NervesSystemCompatibility.Table3

  @spec target_systems :: [atom]
  def target_systems, do: @targets

  @spec build_table :: :ok
  def build_table do
    data = get_data_from_database()

    data_by_target =
      data
      |> Enum.group_by(& &1.target)
      |> Enum.map(fn {target, data} ->
        {target,
         Enum.group_by(data, & &1.version)
         |> Enum.map(fn {version, [entry]} -> {version, entry} end)
         |> Enum.sort_by(fn {version, _} -> version end, {:desc, Version})}
      end)

    html =
      for target <- @targets do
        table_html =
          Table3.build(Access.fetch!(data_by_target, target))
          |> to_string()
          |> Earmark.as_html!()

        "<details><summary>nerves_system_#{target}</summary>#{table_html}</details>"
        |> String.replace(~r/>\s+/, ">")
        |> String.replace(~r/\s+</, "<")
        |> String.replace(~r/ style="text-align: left;"/, "")
      end

    File.mkdir("tmp")
    file = "tmp/nerves_system_compatibility_#{DateTime.to_unix(DateTime.utc_now())}.html"
    IO.puts("writing the Nerves system compatibility information to #{file}")
    File.write!(file, html)
  end

  @doc """
  Returns compatibility data for Nerves Systems.
  """
  @spec get_data_from_database :: [%{binary => any}]
  def get_data_from_database do
    db = %Database{}

    Database.NervesSystemTarget.get(db)
    |> Enum.map(fn nerves_system_target ->
      nerves_system_br =
        Database.NervesSystemBr.get(db, nerves_system_target.nerves_system_br_version)

      nerves_system_target
      |> Map.put(:buildroot_version, nerves_system_br.buildroot_version || :unknown)
      |> Map.put(:otp_version, nerves_system_br.otp_version || :unknown)
    end)
  end

  @doc """
  Builds nerves system info database in the local filesystem.
  """
  def build_database! do
    db = %Database{}
    Database.NervesSystemBr.update(db)
    Database.NervesSystemTarget.update_nerves_system_br_versions(db)
    Database.NervesSystemTarget.update_linux_versions(db)
  end
end
