defmodule NervesSystemCompatibility.Table3 do
  @moduledoc false

  alias NervesSystemCompatibility.Utils

  @column_labels ["", "Nerves System BR", "Erlang/OTP", "Buildroot", "Linux"]
  @row_opts [column_width: 20]

  @doc """
  Converts the compatibility data to a markdown table.
  """
  @spec build([%{binary => any}]) :: binary
  def build(data_by_version) do
    [
      Utils.table_row(@column_labels, @row_opts),
      Utils.divider_row(length(@column_labels), @row_opts),
      data_rows(data_by_version)
    ]
    |> Enum.join("\n")
  end

  defp data_rows(data_by_version) do
    for {version, data_entry} <- data_by_version do
      [
        version,
        data_entry.nerves_system_br_version,
        data_entry.otp_version,
        data_entry.buildroot_version,
        data_entry.linux_version
      ]
      |> Utils.table_row(@row_opts)
    end
    |> Enum.join("\n")
  end
end
