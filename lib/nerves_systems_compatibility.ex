defmodule NervesSystemsCompatibility do
  @moduledoc """
  Documentation for `NervesSystemsCompatibility`.
  """

  @versions Application.compile_env!(:nerves_systems_compatibility, :versions)
  @targets Map.keys(@versions) -- [:otp, :br]

  @doc """
  Returns registered Nerves System versions.
  """
  @spec versions :: %{(target :: atom) => [version :: binary]}
  def versions, do: @versions

  @spec versions(target :: atom | binary) :: [version :: binary]
  def versions(target) when is_binary(target), do: versions(String.to_existing_atom(target))
  def versions(target), do: Access.fetch!(@versions, target)

  @spec targets :: [atom]
  def targets, do: @targets

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
end
