defmodule NervesSystemsCompatibility.SystemVersion do
  @moduledoc false

  # The directory where all the versions files are located.
  @versions_dir Path.join([:code.priv_dir(:nerves_systems_compatibility), "versions"])
  @otp_file Path.join(@versions_dir, "otp")
  @nerves_br_file Path.join(@versions_dir, "nerves_br")
  @nerves_system_files Path.join([@versions_dir, "nerves_system_*"]) |> Path.wildcard()

  @spec otp_versions :: [binary]
  def otp_versions, do: read_lines(@otp_file)

  @spec nerves_br_versions :: [binary]
  def nerves_br_versions, do: read_lines(@nerves_br_file)

  @doc """
  Returns Nerves System versions for all regitered targets.
  """
  @spec nerves_system_versions :: keyword([version :: binary])
  def nerves_system_versions do
    for file_path <- @nerves_system_files, reduce: [] do
      acc ->
        [{file_path_to_existing_target_system_atom(file_path), read_lines(file_path)} | acc]
    end
    |> Enum.reverse()
  end

  @doc """
  Returns Nerves System versions for one regitered target.
  """
  @spec nerves_system_versions(target :: atom | binary) :: [version :: binary]
  def nerves_system_versions(target) do
    Enum.find(@nerves_system_files, &String.ends_with?(&1, to_string(target))) |> read_lines()
  end

  @doc """
  Converts a valid file path to an existing target atom.
  """
  def file_path_to_existing_target_system_atom(file_path) do
    NervesSystemsCompatibility.target_systems()
    |> Enum.find(fn target_system ->
      "#{target_system}" =~ String.replace_prefix(Path.basename(file_path), "nerves_system_", "")
    end) || raise("invalid file path #{file_path}")
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

  defp read_lines(file_path) do
    file_path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.into([])
    |> Enum.to_list()
  end
end
