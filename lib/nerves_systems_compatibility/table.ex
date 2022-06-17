defmodule NervesSystemsCompatibility.Table do
  @moduledoc false

  alias NervesSystemsCompatibility.Data

  @doc """
  Converts the compatibility data to a markdown table.
  """
  @spec build([%{binary => any}]) :: binary
  def build(compatibility_data) do
    system_targets = NervesSystemsCompatibility.targets()
    otp_versions = NervesSystemsCompatibility.versions(:otp)

    [
      header_row(system_targets),
      divider_row(length(system_targets)),
      data_rows(system_targets, otp_versions, compatibility_data)
    ]
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp header_row(targets) when is_list(targets) do
    "| | " <> (targets |> Enum.join(" | ")) <> " |"
  end

  defp divider_row(columm_count) when is_integer(columm_count) do
    "|---|" <> (List.duplicate("---|", columm_count) |> Enum.join(""))
  end

  defp data_rows(targets, otp_versions, compatibility_data) do
    grouped_by_otp_and_target = compatibility_data |> Data.group_data_by_otp_and_target()

    otp_versions
    |> Enum.reduce([], fn otp_version, acc ->
      grouped_by_target = grouped_by_otp_and_target |> Access.fetch!(otp_version)

      target_versions =
        targets
        |> Enum.map(&get_in(grouped_by_target, [&1, "target_version"]))

      [data_row(otp_version, target_versions) | acc]
    end)
    |> Enum.join("\n")
  end

  defp data_row(otp_version, row_values) when is_list(row_values) do
    "| OTP #{otp_version} | " <> Enum.join(row_values, " | ") <> " |"
  end
end
