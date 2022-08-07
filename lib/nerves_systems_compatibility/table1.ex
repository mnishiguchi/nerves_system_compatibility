defmodule NervesSystemsCompatibility.Table1 do
  @moduledoc false

  alias NervesSystemsCompatibility.Data
  alias NervesSystemsCompatibility.Utils

  @row_opts [header_column_width: 12, value_column_width: 10]

  @doc """
  Converts the compatibility data to a markdown table.
  """
  @spec build([%{binary => any}]) :: binary
  def build(compatibility_data) do
    targets = NervesSystemsCompatibility.target_systems()
    otp_versions = NervesSystemsCompatibility.otp_versions()

    [
      Utils.table_row(["" | targets], @row_opts),
      Utils.divider_row(1 + length(targets), @row_opts),
      data_rows(targets, otp_versions, compatibility_data)
    ]
    |> Enum.join("\n")
  end

  defp data_rows(targets, otp_versions, compatibility_data) do
    grouped_by_otp_and_target = compatibility_data |> Data.group_data_by_otp_and_target()

    for otp_version <- otp_versions do
      target_versions =
        for target <- targets do
          grouped_by_otp_and_target
          |> get_in([otp_version, target, "target_version"])
        end

      Utils.table_row(["OTP #{otp_version}" | target_versions], @row_opts)
    end
    |> Enum.reverse()
    |> Enum.join("\n")
  end
end
