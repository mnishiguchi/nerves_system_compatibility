defmodule NervesSystemsCompatibility.Data do
  @moduledoc false

  alias NervesSystemsCompatibility.API
  alias NervesSystemsCompatibility.SystemVersion

  @type compatibility_data :: [%{binary => any}]

  @doc """
  Returns compatibility information for Nerves Systems.
  """
  @spec get :: compatibility_data
  def get do
    target_to_versions_map = NervesSystemsCompatibility.nerves_system_versions()

    nerves_br_version_to_metadata_map =
      NervesSystemsCompatibility.nerves_br_versions()
      |> Enum.map(fn nerves_br_version ->
        Task.async(fn ->
          {nerves_br_version, nerves_br_version_to_metadata(nerves_br_version)}
        end)
      end)
      |> Task.await_many(:timer.seconds(10))
      |> Enum.reduce(%{}, fn {nerves_br_version, nerves_br_metadata}, acc ->
        %{nerves_br_version => nerves_br_metadata} |> Enum.into(acc)
      end)

    target_to_versions_map
    |> Enum.map(fn {target, versions} ->
      Task.async(fn ->
        build_target_metadata(target, versions, nerves_br_version_to_metadata_map)
      end)
    end)
    |> Task.await_many(:timer.seconds(10))
    |> Enum.reduce([], fn target_metadata, acc -> target_metadata ++ acc end)
  end

  defp build_target_metadata(target, target_versions, %{} = nerves_br_version_to_metadata_map) do
    for target_version <- target_versions, into: [] do
      nerves_br_version =
        API.fetch_nerves_br_version_for_target!(target, target_version)
        |> Access.fetch!("nerves_br_version")

      nerves_br_version_to_metadata_map
      |> Access.fetch!(nerves_br_version)
      |> Enum.into(%{
        "target" => target,
        "target_version" => target_version
      })
    end
  end

  defp nerves_br_version_to_metadata(nerves_br_version) do
    [
      Task.async(API, :fetch_buildroot_version!, [nerves_br_version]),
      Task.async(API, :fetch_otp_version!, [nerves_br_version])
    ]
    |> Task.await_many(:timer.seconds(10))
    |> Enum.reduce(%{"nerves_br_version" => nerves_br_version}, fn metadata_map, acc ->
      metadata_map |> Enum.into(acc)
    end)
  end

  @doc """
  Groups the compatibility data by otp version and target.
  """
  @spec group_data_by_otp_and_target(compatibility_data) :: %{binary => %{atom => any}}
  def group_data_by_otp_and_target(compatibility_data) do
    compatibility_data
    |> Enum.group_by(&get_in(&1, ["otp_version"]))
    |> Map.new(fn {otp, otp_entries} ->
      {
        otp,
        otp_entries
        |> Enum.group_by(&get_in(&1, ["target"]))
        |> Map.new(fn {target, target_entries} ->
          {
            target,
            # Pick the latest available nerves system version.
            # Sometimes there are more than one available versions for the same OTP version.
            target_entries
            |> Enum.max_by(
              fn %{"target_version" => target_version} ->
                SystemVersion.normalize_version(target_version)
              end,
              Version
            )
          }
        end)
      }
    end)
  end
end
