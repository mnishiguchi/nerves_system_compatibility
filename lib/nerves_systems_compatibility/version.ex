defmodule NervesSystemsCompatibility.Version do
  @moduledoc false

  @versions_dir Path.join([:code.priv_dir(:nerves_systems_compatibility), "versions"])

  @nerves_system_files Path.join([@versions_dir, "nerves_system_*"]) |> Path.wildcard()

  @targets @nerves_system_files
           |> Enum.map(fn absolute_path ->
             absolute_path
             |> Path.basename()
             |> String.replace_prefix("nerves_system_", "")
             |> String.to_atom()
           end)

  @spec targets :: [atom]
  def targets, do: @targets

  @spec otp_versions :: [binary]
  def otp_versions, do: Path.join(@versions_dir, "otp") |> read_lines()

  @spec nerves_br_versions :: [binary]
  def nerves_br_versions, do: Path.join(@versions_dir, "nerves_br") |> read_lines()

  @doc """
  Returns Nerves System versions for all regitered targets.
  """
  @spec nerves_system_versions :: keyword([version :: binary])
  def nerves_system_versions do
    @nerves_system_files
    |> Enum.reduce([], fn file_path, acc ->
      [
        {
          Path.basename(file_path)
          |> String.replace_prefix("nerves_system_", "")
          |> String.to_existing_atom(),
          read_lines(file_path)
        }
        | acc
      ]
    end)
    |> Enum.reverse()
  end

  @doc """
  Returns Nerves System versions for one regitered target.
  """
  @spec nerves_system_versions(target :: atom | binary) :: [version :: binary]
  def nerves_system_versions(target) do
    read_lines(Path.join(@versions_dir, "nerves_system_#{target}"))
  end

  @doc """
  Supplements missing minor and patch values so that the version can be compared.
  """
  def normalize_version(version) do
    case version |> String.split(".") |> Enum.map(&String.to_integer/1) |> length() do
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
