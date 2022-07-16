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

  @targets ~w[
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

  alias NervesSystemsCompatibility.Data
  alias NervesSystemsCompatibility.Table1
  alias NervesSystemsCompatibility.Table2

  @spec otp_versions :: [binary]
  def otp_versions, do: @otp_versions

  @spec target_systems :: [atom]
  def target_systems, do: @targets

  @spec build_table(:table1) :: iodata
  def build_table(:table1) do
    Table1.build(Data.get())
  end

  @spec build_table(:table2) :: [{atom, iodata}]
  def build_table(:table2) do
    compatibility_data = Data.get()
    data_by_target = Data.group_data_by_target(compatibility_data)

    for target <- @targets do
      {
        target,
        Table2.build(
          target,
          Access.fetch!(data_by_target, target),
          Data.list_target_system_versions(compatibility_data, target)
        )
      }
    end
  end
end
