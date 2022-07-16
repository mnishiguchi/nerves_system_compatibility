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

  def build_table(:table1) do
    NervesSystemsCompatibility.Data.get()
    |> NervesSystemsCompatibility.Table1.build()
  end

  def build_table(:table2) do
    NervesSystemsCompatibility.Data.get()
    |> NervesSystemsCompatibility.Table2.build()
  end
end
