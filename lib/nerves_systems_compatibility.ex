defmodule NervesSystemsCompatibility do
  @moduledoc """
  Documentation for `NervesSystemsCompatibility`.
  """

  alias NervesSystemsCompatibility.API

  @doc """
  Returns registered Nerves System versions.
  """
  @spec versions :: %{(target :: atom) => [version :: binary]}
  def versions, do: Application.fetch_env!(:nerves_systems_compatibility, :versions)

  @spec versions(target :: atom | binary) :: [version :: binary]
  def versions(target) when is_binary(target), do: versions(String.to_existing_atom(target))
  def versions(target), do: Access.fetch!(versions(), target)

  @spec targets :: [atom]
  def targets, do: Map.keys(versions())

  @doc """
  Returns compatibility data for Nerves Systems.
  """
  @spec get :: %{(target :: atom) => %{(version :: binary) => %{binary => binary}}}
  def get do
    {%{br: nerves_br_versions}, system_target_to_versions_map} =
      NervesSystemsCompatibility.versions() |> Map.split([:br])

    nerves_br_version_to_metadata_map =
      nerves_br_versions
      |> Enum.map(fn nerves_br_version ->
        Task.async(fn ->
          {nerves_br_version, nerves_br_version_to_metadata!(nerves_br_version)}
        end)
      end)
      |> Task.await_many(:timer.seconds(10))
      |> Enum.reduce(%{}, fn {nerves_br_version, nerves_br_metadata}, acc ->
        %{nerves_br_version => nerves_br_metadata} |> Enum.into(acc)
      end)

    system_target_to_versions_map
    |> Enum.map(fn {target, versions} ->
      Task.async(fn ->
        {target, build_target_metadata(target, versions, nerves_br_version_to_metadata_map)}
      end)
    end)
    |> Task.await_many(:timer.seconds(10))
    |> Enum.reduce(%{}, fn {target, target_version_to_nerves_br_metadata}, result ->
      %{target => target_version_to_nerves_br_metadata} |> Enum.into(result)
    end)
  end

  defp build_target_metadata(target, versions, %{} = nerves_br_version_to_metadata_map) do
    for version <- versions, into: %{} do
      %{"nerves_br" => nerves_br_version} =
        API.fetch_nerves_br_version_for_target!(target, version)

      {version,
       nerves_br_version_to_metadata_map
       |> Access.fetch!(nerves_br_version)
       |> Enum.into(%{"target" => {target, version}})}
    end
  end

  defp nerves_br_version_to_metadata!(nerves_br_version) do
    [
      Task.async(API, :fetch_buildroot_version!, [nerves_br_version]),
      Task.async(API, :fetch_otp_version!, [nerves_br_version])
    ]
    |> Task.await_many(:timer.seconds(10))
    |> Enum.reduce(%{"nerves_br" => nerves_br_version}, fn metadata_map, acc ->
      metadata_map |> Enum.into(acc)
    end)
  end
end
