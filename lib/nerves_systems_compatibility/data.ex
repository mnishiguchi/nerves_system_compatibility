defmodule NervesSystemsCompatibility.Data do
  @moduledoc false

  alias NervesSystemsCompatibility.API

  @type compatibility_data :: [%{binary => any}]

  @doc """
  Returns compatibility information for Nerves Systems.
  """
  @spec get :: compatibility_data
  def get do
    nerves_br_version_to_metadata_map =
      API.fetch_nerves_br_versions!()
      |> Task.async_stream(&{&1, nerves_br_version_to_metadata(&1)}, timeout: 10_000)
      |> Enum.reduce(%{}, fn {:ok, {nerves_br_version, nerves_br_metadata}}, acc ->
        Map.put(acc, nerves_br_version, nerves_br_metadata)
      end)

    API.fetch_nerves_system_versions!()
    |> Task.async_stream(
      fn {target, versions} ->
        build_target_metadata(target, versions, nerves_br_version_to_metadata_map)
      end,
      timeout: 10_000
    )
    |> Enum.reduce([], fn {:ok, target_metadata}, acc -> target_metadata ++ acc end)
  end

  defp build_target_metadata(target, target_versions, %{} = nerves_br_version_to_metadata_map) do
    for target_version <- target_versions, into: [] do
      nerves_br_version =
        API.fetch_nerves_br_version_for_target!(target, target_version)
        |> Access.fetch!("nerves_br_version")

      if metadata_map = nerves_br_version_to_metadata_map[nerves_br_version] do
        metadata_map
        |> Map.put("target", target)
        |> Map.put("target_version", target_version)
      else
        nil
      end
    end
    |> Enum.reject(&is_nil/1)
  end

  defp nerves_br_version_to_metadata(nerves_br_version) do
    [
      Task.async(API, :fetch_buildroot_version!, [nerves_br_version]),
      Task.async(API, :fetch_otp_version!, [nerves_br_version])
    ]
    |> Task.await_many(:timer.seconds(10))
    |> Enum.reduce(%{"nerves_br_version" => nerves_br_version}, fn %{} = data, acc ->
      Map.merge(acc, data)
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
            |> Enum.reject(fn %{"target_version" => target_version} ->
              String.match?(target_version, ~r/-rc/)
            end)
            |> Enum.max_by(
              fn %{"target_version" => target_version} ->
                normalize_version(target_version)
              end,
              Version
            )
          }
        end)
      }
    end)
  end

  @doc """
  Supplements missing minor and patch values so that the version can be compared.
  """
  def normalize_version(version) do
    case version |> String.split(".") |> Enum.count(&String.to_integer/1) do
      1 -> version <> ".0.0"
      2 -> version <> ".0"
      3 -> version
      _ -> raise("invalid version #{inspect(version)}")
    end
  end
end
