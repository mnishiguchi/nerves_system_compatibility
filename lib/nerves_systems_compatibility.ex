defmodule NervesSystemsCompatibility do
  @moduledoc """
  Documentation for `NervesSystemsCompatibility`.
  """

  @versions_dir Path.join([:code.priv_dir(:nerves_systems_compatibility), "versions"])

  @targets Path.join([@versions_dir, "nerves_system_*"])
           |> Path.wildcard()
           |> Enum.map(fn absolute_path ->
             absolute_path
             |> Path.basename()
             |> String.replace_prefix("nerves_system_", "")
             |> String.to_atom()
           end)

  @spec targets :: [atom]
  def targets, do: @targets

  @spec otp_versions :: [binary]
  def otp_versions, do: read_lines(Path.join(@versions_dir, "otp"))

  @spec nerves_br_versions :: [binary]
  def nerves_br_versions, do: read_lines(Path.join(@versions_dir, "nerves_br"))

  @doc """
  Returns Nerves System versions for all regitered targets.
  """
  @spec nerves_system_versions :: keyword([version :: binary])
  def nerves_system_versions do
    Path.join([@versions_dir, "nerves_system_*"])
    |> Path.wildcard()
    |> Enum.reduce([], fn file_path, acc ->
      [
        {
          Path.basename(file_path)
          |> String.replace_prefix("nerves_system_", "")
          |> String.to_existing_atom(),
          read_lines(file_path)
        }
        | acc
      ]
    end)
    |> Enum.reverse()
  end

  @doc """
  Returns Nerves System versions for one regitered target.
  """
  @spec nerves_system_versions(target :: atom | binary) :: [version :: binary]
  def nerves_system_versions(target) do
    read_lines(Path.join(@versions_dir, "nerves_system_#{target}"))
  end

  @doc """
  Returns compatibility data for Nerves Systems.
  """
  @spec get_data :: [%{binary => any}]
  defdelegate get_data,
    to: NervesSystemsCompatibility.Data,
    as: :get

  @doc """
  Converts compatibility data to a markdown table
  """
  @spec build_table([%{binary => any}]) :: binary
  defdelegate build_table(compatibility_data \\ get_data()),
    to: NervesSystemsCompatibility.Table,
    as: :build

  defp read_lines(file_path) do
    file_path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.into([])
    |> Enum.to_list()
  end
end
