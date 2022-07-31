defmodule NervesSystemCompatibility.Utils do
  @moduledoc false

  @doc """
  Generates a header row for a markdown table

  ## Examples

      iex> Utils.table_row(["", "a", "b", "c"])
      "|          | a        | b        | c        |"

      iex> Utils.table_row(["", "a", "b", "c"], header_column_width: 3, value_column_width: 6)
      "|   | a    | b    | c    |"

      iex> Utils.table_row(["", "a", "b", "c"], column_width: 3)
      "|   | a | b | c |"

  """
  def table_row(values, opts \\ []) when is_list(values) do
    column_width = opts[:column_width] || 10
    header_column_width = opts[:header_column_width] || column_width
    value_column_width = opts[:value_column_width] || column_width

    [header | rest] = values

    [
      "|",
      [
        pad_table_cell(header, header_column_width)
        | Enum.map(rest, &pad_table_cell(&1, value_column_width))
      ]
      |> Enum.intersperse("|"),
      "|"
    ]
    |> Enum.join()
  end

  @doc """
  Generates a divider row for a markdown table

  ## Examples

      iex> Utils.divider_row(6)
      "| ---      | ---      | ---      | ---      | ---      | ---      |"

      iex> Utils.divider_row(6, header_column_width: 12, value_column_width: 6)
      "| ---        | ---  | ---  | ---  | ---  | ---  |"

  """
  def divider_row(cell_count, opts \\ []) when is_integer(cell_count) do
    column_width = opts[:column_width] || 10
    header_column_width = opts[:header_column_width] || column_width
    value_column_width = opts[:value_column_width] || column_width

    [
      "|",
      [
        pad_table_cell("---", header_column_width)
        | List.duplicate(pad_table_cell("---", value_column_width), cell_count - 1)
      ]
      |> Enum.intersperse("|"),
      "|"
    ]
    |> Enum.join()
  end

  @doc """
  Pads a value with spaces

  ## Examples

      iex> Utils.pad_table_cell("hello")
      " hello    "

      iex> Utils.pad_table_cell("hello", 12)
      " hello      "

  """
  def pad_table_cell(value, count \\ 10) do
    String.pad_trailing(" #{value}", count)
  end

  @doc """
  Supplements missing minor and patch values so that the version can be compared.
  """
  def normalize_version(version) do
    case version |> String.split(".") |> Enum.count(&String.to_integer/1) do
      1 -> version <> ".0.0"
      2 -> version <> ".0"
      3 -> version
      _ -> raise("invalid version #{inspect(version)}")
    end
  end
end
