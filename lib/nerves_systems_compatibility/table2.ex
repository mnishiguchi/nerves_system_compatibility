defmodule NervesSystemsCompatibility.Table2 do
  @moduledoc false

  alias NervesSystemsCompatibility.Utils

  @default_column_names ["", "Erlang/OTP", "nerves_system_br", "Buildroot"]
  @row_opts [column_width: 20]

  @doc """
  Converts the compatibility data to a markdown table.
  """
  @spec build(atom, [%{binary => any}], [binary]) :: binary
  def build(target, data_by_system_version, system_versions) do
    column_names = build_column_names(target)

    [
      Utils.table_row(column_names, @row_opts),
      Utils.divider_row(length(column_names), @row_opts),
      data_rows(data_by_system_version, system_versions)
    ]
    |> Enum.join("\n")
  end

  defp build_column_names(target) do
    ["nerves_system_#{target}" | tl(@default_column_names)]
  end

  defp data_rows(data_by_system_version, system_versions) do
    for system_version <- system_versions do
      data_entry = Access.fetch!(data_by_system_version, system_version)

      Utils.table_row(
        Enum.concat(
          [system_version],
          [
            Access.fetch!(data_entry, "otp_version"),
            Access.fetch!(data_entry, "nerves_br_version"),
            Access.fetch!(data_entry, "buildroot_version")
          ]
        ),
        @row_opts
      )
    end
    |> Enum.join("\n")
  end
end
