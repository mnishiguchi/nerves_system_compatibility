defmodule NervesSystemsCompatibility do
  @moduledoc """
  Documentation for `NervesSystemsCompatibility`.
  """

  alias NervesSystemsCompatibility.Repo

  @doc """
  Returns registered Nerves System versions.
  """
  def versions, do: Application.fetch_env!(:nerves_systems_compatibility, :versions)
  def versions(target) when is_binary(target), do: versions(String.to_existing_atom(target))
  def versions(target), do: Access.fetch!(versions(), target)

  def get do
    {%{br: system_br_versions}, system_target_to_versions_map} =
      NervesSystemsCompatibility.versions() |> Map.split([:br])

    system_br_version_to_metadata_map =
      Enum.reduce(system_br_versions, %{}, fn system_br_version, acc ->
        put_in(
          acc,
          [system_br_version],
          Repo.get_system_br_metadata!(system_br_version)
        )
      end)

    Enum.reduce(system_target_to_versions_map, %{}, fn {target, tags}, result ->
      target_tag_to_system_br_metadata =
        Enum.reduce(tags, %{}, fn tag, acc ->
          %{
            tag =>
              system_br_version_to_metadata_map
              |> Access.fetch!(Repo.get_system_br_version_for_target!(target, tag))
          }
          |> Enum.into(acc)
        end)

      put_in(result, [target], target_tag_to_system_br_metadata)
    end)
  end
end
