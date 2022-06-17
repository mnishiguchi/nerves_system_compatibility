defmodule NervesSystemsCompatibility do
  @moduledoc """
  Documentation for `NervesSystemsCompatibility`.
  """

  alias NervesSystemsCompatibility.API

  @doc """
  Returns registered Nerves System versions.
  """
  @spec versions :: %{(target :: atom) => [tag :: binary]}
  def versions, do: Application.fetch_env!(:nerves_systems_compatibility, :versions)

  @spec versions(target :: atom | binary) :: [tag :: binary]
  def versions(target) when is_binary(target), do: versions(String.to_existing_atom(target))
  def versions(target), do: Access.fetch!(versions(), target)

  @doc """
  Returns compatibility data for Nerves Systems.
  """
  @spec get :: %{(target :: atom) => %{(tag :: binary) => %{(key :: binary) => value :: binary}}}
  def get do
    {%{br: nerves_br_versions}, system_target_to_tags_map} =
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

    system_target_to_tags_map
    |> Enum.map(fn {target, tags} ->
      Task.async(fn ->
        {target, build_target_metadata(target, tags, nerves_br_version_to_metadata_map)}
      end)
    end)
    |> Task.await_many(:timer.seconds(10))
    |> Enum.reduce(%{}, fn {target, target_tag_to_nerves_br_metadata}, result ->
      %{target => target_tag_to_nerves_br_metadata} |> Enum.into(result)
    end)
  end

  defp build_target_metadata(target, tags, %{} = nerves_br_version_to_metadata_map) do
    for tag <- tags, into: %{} do
      nerves_br_version = API.fetch_nerves_br_version_for_target!(target, tag)

      {tag, nerves_br_version_to_metadata_map |> Access.fetch!(nerves_br_version)}
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
