defmodule NervesSystemsCompatibility do
  @moduledoc """
  Documentation for `NervesSystemsCompatibility`.
  """

  @otp_versions ~w[
    23.2.4
    23.2.7
    23.3.1
    24.0.2
    24.0.5
    24.1
    24.1.2
    24.1.4
    24.1.7
    24.2
    24.2.2
    24.3.2
    25.0
  ]

  @target_systems ~w[
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

  @spec otp_versions :: [binary]
  def otp_versions, do: @otp_versions

  @spec target_systems :: [atom]
  def target_systems, do: @target_systems

  @spec nerves_br_versions :: [binary]
  defdelegate nerves_br_versions,
    to: NervesSystemsCompatibility.API,
    as: :fetch_nerves_br_versions!

  @doc """
  Returns Nerves System versions for all regitered targets.
  """
  @spec nerves_system_versions :: keyword([version :: binary])
  defdelegate nerves_system_versions,
    to: NervesSystemsCompatibility.API,
    as: :fetch_nerves_system_versions!

  @doc """
  Returns Nerves System versions for one regitered target.
  """
  @spec nerves_system_versions(target :: atom | binary) :: [version :: binary]
  defdelegate nerves_system_versions(target),
    to: NervesSystemsCompatibility.API,
    as: :fetch_nerves_system_versions!

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
