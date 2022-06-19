defmodule NervesSystemsCompatibility do
  @moduledoc """
  Documentation for `NervesSystemsCompatibility`.
  """

  @spec targets :: [atom]
  defdelegate targets,
    to: NervesSystemsCompatibility.Version

  @spec otp_versions :: [binary]
  defdelegate otp_versions,
    to: NervesSystemsCompatibility.Version

  @spec nerves_br_versions :: [binary]
  defdelegate nerves_br_versions,
    to: NervesSystemsCompatibility.Version

  @doc """
  Returns Nerves System versions for all regitered targets.
  """
  @spec nerves_system_versions :: keyword([version :: binary])
  defdelegate nerves_system_versions,
    to: NervesSystemsCompatibility.Version

  @doc """
  Returns Nerves System versions for one regitered target.
  """
  @spec nerves_system_versions(target :: atom | binary) :: [version :: binary]
  defdelegate nerves_system_versions(target),
    to: NervesSystemsCompatibility.Version

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
