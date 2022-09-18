defmodule NervesSystemCompatibility.Repo do
  @moduledoc """
  Get information on Nerves systems from Github repos.

  ## Examples

      targets = NervesSystemCompatibility.nerves_targets()

      Repo.download_nerves_system_repos([:grisp2])

      Repo.get_nerves_system_target_versions([:grisp2])

      Repo.get_nerves_system_br_versions_for_target(:rpi0, "1.20.0")

      Repo.get_buildroot_versions(["1.20.0"])

      Repo.get_otp_version("1.20.0")

      Repo.get_linux_version_for_target(:rpi, "1.20.0")

  """

  alias NervesSystemCompatibility.Utils

  @download_dir "tmp/data/repos"
  @br_version_count 150
  @target_version_count 50

  ## repos

  @spec download_nerves_system_repos([atom]) :: [{:ok, any} | {:error, any}]
  def download_nerves_system_repos(targets \\ [:br | NervesSystemCompatibility.nerves_targets()]) do
    targets
    |> Enum.map(&Task.async(fn -> download_nerves_system_repo(&1) end))
    |> Enum.map(&Task.await(&1, :infinity))
  end

  @spec download_nerves_system_repo(atom) :: {:ok, any} | {:error, any}
  def download_nerves_system_repo(target_or_br) do
    repo_dir = nerves_system_repo_dir(target_or_br)

    if File.exists?(repo_dir) do
      {:error, {:already_exists, repo_dir}}
    else
      download_github_repo("nerves-project/nerves_system_#{target_or_br}")
    end
  end

  @spec download_github_repo(String.t()) :: {:ok, any} | {:error, any}
  def download_github_repo(repo_name) do
    repo_dir = repo_name |> String.split("/") |> List.last() |> repo_dir()

    if File.exists?(repo_dir) do
      {:error, {:already_exists, repo_dir}}
    else
      cd = download_dir()

      case System.cmd("git", ["clone", "https://github.com/#{repo_name}.git"], cd: cd) do
        {_, 0} ->
          {:ok, repo_dir}

        error ->
          {:error, error}
      end
    end
  end

  ## nerves_system_* versions

  @spec get_nerves_system_br_versions :: [binary] | {:error, {any, pos_integer}}
  def get_nerves_system_br_versions do
    get_nerves_system_versions(:br, version_count: @br_version_count)
  end

  @spec get_nerves_system_target_versions([atom]) :: map | {:error, any}
  def get_nerves_system_target_versions(targets) when is_list(targets) do
    Enum.map(targets, &{&1, get_nerves_system_versions(&1)}) |> Enum.into(%{})
  end

  @spec get_nerves_system_versions(atom, keyword()) :: [String.t()] | {:error, any}
  def get_nerves_system_versions(target_or_br, opts \\ []) when is_atom(target_or_br) do
    cd = "#{download_dir()}/nerves_system_#{target_or_br}"
    version_count = opts[:version_count] || @target_version_count

    case System.cmd("git", ["tag"], cd: cd) do
      {result, 0} ->
        result
        |> String.split("\n")
        |> Enum.filter(&String.match?(&1, ~r/\d*\.\d*\.\d*$/))
        |> Enum.map(&String.replace_leading(&1, "v", ""))
        |> Enum.sort({:desc, Version})
        |> Enum.take(version_count)

      error ->
        {:error, error}
    end
  end

  ## nerves_system_br versions that target systems depend on

  @spec get_nerves_system_br_versions_for_targets([atom]) :: map
  def get_nerves_system_br_versions_for_targets(targets) when is_list(targets) do
    get_nerves_system_target_versions(targets)
    |> Enum.map(fn {target, versions} ->
      Task.async(fn ->
        for version <- versions, into: %{} do
          {{target, version}, get_nerves_system_br_versions_for_target(target, version)}
        end
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> Enum.reduce(%{}, &Enum.into/2)
  end

  @spec get_nerves_system_br_versions_for_target(atom, String.t()) :: {:error, any} | {:ok, any}
  def get_nerves_system_br_versions_for_target(target, version) do
    cd = "#{download_dir()}/nerves_system_#{target}"
    cmd = "cd #{cd} && git checkout v#{version} > /dev/null 2>&1 && grep nerves_system_br mix.exs"

    case System.shell(cmd) do
      {result, 0} ->
        captures =
          Regex.named_captures(
            ~r/:nerves_system_br, "(?<nerves_system_br_version>(\d+\.)?(\d+\.)?(\*|\d+))"/i,
            result
          )

        captures["nerves_system_br_version"]

      error ->
        {:error, error}
    end
  end

  ## buildroot versions

  @spec get_buildroot_version(String.t()) :: String.t()
  def get_buildroot_version(nerves_system_br_version) when is_binary(nerves_system_br_version) do
    cd = "#{download_dir()}/nerves_system_br"

    cmd =
      "cd #{cd} && git checkout v#{nerves_system_br_version} > /dev/null 2>&1 && grep NERVES_BR_VERSION create-build.sh"

    case System.shell(cmd) do
      {result, 0} ->
        captures =
          Regex.named_captures(
            ~r/NERVES_BR_VERSION=(?<buildroot_version>[0-9.]*)/,
            result
          )

        captures["buildroot_version"]

      error ->
        {:error, error}
    end
  end

  ## OTP versions

  @spec get_otp_version(String.t()) :: String.t() | nil | {:error, any}
  def get_otp_version(nerves_system_br_version) do
    cond do
      Version.match?(nerves_system_br_version, ">= 1.12.0") ->
        get_otp_version_from_nerves_system_br_tool_versions(nerves_system_br_version)

      Version.match?(nerves_system_br_version, ">= 1.7.3") ->
        get_otp_version_from_dockerfile(nerves_system_br_version)

      Version.match?(nerves_system_br_version, ">= 0.2.3") ->
        get_otp_version_from_patch(nerves_system_br_version)

      true ->
        {:error, {:unsupported_nerves_system_br_version, nerves_system_br_version}}
    end
  end

  @spec get_otp_version_from_nerves_system_br_tool_versions(String.t()) ::
          String.t() | nil | {:error, any}
  def get_otp_version_from_nerves_system_br_tool_versions(nerves_system_br_version) do
    cd = "#{download_dir()}/nerves_system_br"

    cmd =
      "cd #{cd} && git checkout v#{nerves_system_br_version} > /dev/null 2>&1 && cat .tool-versions"

    case System.shell(cmd) do
      {result, 0} ->
        captures = Regex.named_captures(~r/erlang (?<otp_version>[0-9.]*)/, result)
        captures["otp_version"]

      error ->
        {:error, error}
    end
  end

  @spec get_otp_version_from_dockerfile(String.t()) :: String.t() | nil | {:error, any}
  def get_otp_version_from_dockerfile(nerves_system_br_version) do
    cd = "#{download_dir()}/nerves_system_br"

    dockerfile =
      cond do
        Version.match?(nerves_system_br_version, "> 1.4.0") ->
          "support/docker/nerves_system_br/Dockerfile"

        Version.match?(nerves_system_br_version, ">= 0.16.2") ->
          "support/docker/nerves/Dockerfile"

        true ->
          raise "no dockerfile before 0.16.2"
      end

    cmd =
      "cd #{cd} && git checkout v#{nerves_system_br_version} > /dev/null 2>&1 && cat #{dockerfile}"

    case System.shell(cmd) do
      {result, 0} ->
        captures =
          [
            Regex.named_captures(
              ~r/FROM hexpm\/erlang\:(?<otp_version>(\d+\.)?(\d+\.)?(\*|\d+))/i,
              result
            ),
            Regex.named_captures(
              ~r/ERLANG_OTP_VERSION=(?<otp_version>(\d+\.)?(\d+\.)?(\*|\d+))/i,
              result
            )
          ]
          |> Enum.reject(&is_nil/1)
          |> List.first()

        if captures, do: captures["otp_version"]

      error ->
        {:error, error}
    end
  end

  @spec get_otp_version_from_patch(String.t()) :: String.t()
  def get_otp_version_from_patch(nerves_system_br_version) do
    cd = "#{download_dir()}/nerves_system_br"

    cmd =
      "cd #{cd} && git checkout v#{nerves_system_br_version} > /dev/null 2>&1 && find . -name *.patch"

    case System.shell(cmd) do
      {result, 0} ->
        captures =
          Regex.named_captures(
            ~r/(erlang|otp).*-(?<otp_version>(\d+\.)?(\d+\.)?(\d+)).patch/i,
            result
          )

        captures["otp_version"]

      error ->
        {:error, error}
    end
  end

  ## Linux versions

  @spec get_linux_version_for_target(atom, String.t()) :: String.t()
  def get_linux_version_for_target(target, version) do
    cd = "#{download_dir()}/nerves_system_#{target}"
    cmd = "cd #{cd} && git checkout v#{version} > /dev/null 2>&1 && cat nerves_defconfig"

    case System.shell(cmd) do
      {result, 0} ->
        [
          Regex.named_captures(
            ~r/BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="(?<linux_version>(\d+\.)?(\d+\.)?(\*|\d+))"/i,
            result
          ),
          Regex.named_captures(
            ~r/linux-(?<linux_version>(\d+\.)?(\d+\.)?(\*|\d+))\.defconfig/i,
            result
          )
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.map(&Map.fetch!(&1, "linux_version"))
        |> Enum.sort_by(&Utils.normalize_version/1, :desc)
        |> List.first()

      error ->
        {:error, error}
    end
  end

  ## directories

  @spec download_dir :: String.t()
  def download_dir() do
    _ = File.mkdir_p(@download_dir)
    @download_dir
  end

  @spec nerves_system_repo_dir(atom) :: String.t()
  def nerves_system_repo_dir(target_or_br \\ :br) do
    repo_dir("nerves_system_#{target_or_br}")
  end

  @spec repo_dir(String.t()) :: String.t()
  def repo_dir(project_name) do
    "#{@download_dir}/#{project_name}"
  end
end
