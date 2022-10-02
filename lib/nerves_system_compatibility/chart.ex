defmodule NervesSystemCompatibility.Chart do
  alias NervesSystemCompatibility.Database

  @chart_dir "tmp/nerves_system_compatibility"

  def build(opts \\ []) do
    chart_dir = opts[:chart_dir] || @chart_dir
    chart_format = opts[:format] || :md

    chart =
      for target <- NervesSystemCompatibility.nerves_targets() do
        build_chart_for_target(target, opts)
      end
      |> Enum.join("\n\n")

    File.mkdir_p(chart_dir)
    file = "#{chart_dir}/nerves_system_compatibility_#{System.os_time(:second)}.#{chart_format}"
    IO.puts(file)
    File.write!(file, chart)
  end

  defp build_chart_for_target(target, opts) do
    column_labels = [target, "Erlang/OTP", "Nerves", "Nerves System BR", "Buildroot", "Linux"]
    header_rows = [table_row(column_labels), divider_row(length(column_labels))]

    data_rows =
      for version <- Database.get({target, :versions}) do
        data = get_data_for_target(target, version)

        values = [
          version,
          data.otp_version,
          data.nerves_version,
          data.nerves_system_br_version,
          data.buildroot_version,
          data.linux_version
        ]

        table_row(values)
      end

    markdown_chart = (header_rows ++ data_rows) |> Enum.join("\n")

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

  defp get_data_for_target(target, version) do
    nerves_system_br_version = Database.get({target, version, :nerves_system_br_version})

    %{
      target: target,
      version: version,
      nerves_version: Database.get({target, version, :nerves_version}),
      nerves_system_br_version: nerves_system_br_version,
      linux_version: Database.get({target, version, :linux_version}),
      buildroot_version: Database.get({:br, nerves_system_br_version, :buildroot_version}),
      otp_version: Database.get({:br, nerves_system_br_version, :otp_version})
    }
  end

  defp table_row(values) when is_list(values) do
    ["|", Enum.map(values, &pad_table_cell/1) |> Enum.intersperse("|"), "|"]
    |> Enum.join()
  end

  defp divider_row(cell_count) when is_integer(cell_count) do
    ["|", List.duplicate(pad_table_cell("---"), cell_count) |> Enum.intersperse("|"), "|"]
    |> Enum.join()
  end

  defp pad_table_cell(value), do: " #{value} "
end
