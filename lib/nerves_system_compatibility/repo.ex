defmodule NervesSystemCompatibility.Repo do
  @moduledoc """
  Get information on Nerves systems from Github repos.
  """

  @download_dir "tmp/nerves_system_compatibility/repos"
  @br_version_count 150
  @target_version_count 50

  def download_nerves_system_repos do
    for target_or_br <- [:br | NervesSystemCompatibility.nerves_targets()] do
      Task.async(fn -> download_nerves_system_repo(target_or_br) end)
    end
    |> Task.await_many(:infinity)

    IO.write("\n")
  end

  def download_nerves_system_repo(target_or_br) do
    project_name = "nerves_system_#{target_or_br}"
    repo_dir = "#{@download_dir}/#{project_name}"

    if File.exists?(repo_dir) do
      System.shell("cd #{repo_dir} && git fetch origin")
    else
      File.mkdir_p(@download_dir)
      remote_repo_url = "https://github.com/nerves-project/#{project_name}.git"
      cmd = "cd #{@download_dir} && git clone #{remote_repo_url} > /dev/null 2>&1"
      IO.puts(cmd)

      case System.shell(cmd) do
        {_, 0} -> :ok
        _error -> raise("Could not download #{remote_repo_url}")
      end
    end

    IO.write(".")
  end

  def get_nerves_system_br_versions do
    get_nerves_system_versions(:br, version_count: @br_version_count)
  end

  def get_nerves_system_target_versions(targets) when is_list(targets) do
    Enum.map(targets, &{&1, get_nerves_system_versions(&1)}) |> Enum.into(%{})
  end

  def get_nerves_system_versions(target_or_br, opts \\ []) when is_atom(target_or_br) do
    cd = "#{@download_dir}/nerves_system_#{target_or_br}"
    version_count = opts[:version_count] || @target_version_count

    case System.cmd("git", ["tag"], cd: cd) do
      {result, 0} ->
        result
        |> String.split("\n")
        |> Enum.filter(&String.match?(&1, ~r/\d*\.\d*\.\d*$/))
        |> Enum.map(&String.replace_leading(&1, "v", ""))
        |> Enum.sort({:desc, Version})
        |> Enum.take(version_count)

      _ ->
        nil
    end
  end

  def get_nerves_system_br_version_for_target(target, version) do
    cd = "#{@download_dir}/nerves_system_#{target}"

    cmd =
      "cd #{cd} && git checkout v#{version} > /dev/null 2>&1 && grep :nerves_system_br, mix.exs"

    case System.shell(cmd) do
      {result, 0} ->
        captures =
          Regex.named_captures(
            ~r/:nerves_system_br, "(?<nerves_system_br_version>.*)"/i,
            result
          )

        captures["nerves_system_br_version"]

      _ ->
        nil
    end
  end

  def get_nerves_version_for_target(target, version) do
    cd = "#{@download_dir}/nerves_system_#{target}"
    cmd = "cd #{cd} && git checkout v#{version} > /dev/null 2>&1 && grep :nerves, mix.exs"

    case System.shell(cmd) do
      {result, 0} ->
        captures =
          Regex.named_captures(
            ~r/:nerves, "(?<nerves_version>.*)"/i,
            result
          )

        captures["nerves_version"]

      _ ->
        nil
    end
  end

  def get_buildroot_version(nerves_system_br_version)
      when is_binary(nerves_system_br_version) do
    cd = "#{@download_dir}/nerves_system_br"

    cmd =
      "cd #{cd} && git checkout v#{nerves_system_br_version} > /dev/null 2>&1 && grep NERVES_BR_VERSION create-build.sh 2>/dev/null"

    case System.shell(cmd) do
      {result, 0} ->
        captures =
          Regex.named_captures(
            ~r/NERVES_BR_VERSION=(?<buildroot_version>[0-9.]*)/,
            result
          )

        captures["buildroot_version"]

      _ ->
        nil
    end
  end

  def get_otp_version(nerves_system_br_version) do
    cond do
      Version.match?(nerves_system_br_version, ">= 1.12.0") ->
        get_otp_version_from_nerves_system_br_tool_versions(nerves_system_br_version)

      Version.match?(nerves_system_br_version, ">= 1.7.3") ->
        get_otp_version_from_dockerfile(nerves_system_br_version)

      Version.match?(nerves_system_br_version, ">= 0.2.3") ->
        get_otp_version_from_patch(nerves_system_br_version)

      true ->
        raise "unsupported nerves_system_br version #{nerves_system_br_version}"
    end
  end

  def get_otp_version_from_nerves_system_br_tool_versions(nerves_system_br_version) do
    cd = "#{@download_dir}/nerves_system_br"

    cmd =
      "cd #{cd} && git checkout v#{nerves_system_br_version} > /dev/null 2>&1 && cat .tool-versions"

    case System.shell(cmd) do
      {result, 0} ->
        captures = Regex.named_captures(~r/erlang (?<otp_version>[0-9.]*)/, result)
        captures["otp_version"]

      _ ->
        nil
    end
  end

  def get_otp_version_from_dockerfile(nerves_system_br_version) do
    dockerfile =
      cond do
        Version.match?(nerves_system_br_version, "> 1.4.0") ->
          "support/docker/nerves_system_br/Dockerfile"

        Version.match?(nerves_system_br_version, ">= 0.16.2") ->
          "support/docker/nerves/Dockerfile"

        true ->
          raise "no dockerfile before 0.16.2"
      end

    cd = "#{@download_dir}/nerves_system_br"

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

      _ ->
        nil
    end
  end

  def get_otp_version_from_patch(nerves_system_br_version) do
    cd = "#{@download_dir}/nerves_system_br"

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

      _ ->
        nil
    end
  end

  def get_linux_version_for_target(target, version) do
    cd = "#{@download_dir}/nerves_system_#{target}"
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
        |> Enum.sort_by(&normalize_version/1, {:desc, Version})
        |> List.first()

      _ ->
        nil
    end
  end

  def normalize_version(version) do
    case version |> String.split(".") |> Enum.count(&String.to_integer/1) do
      1 -> version <> ".0.0"
      2 -> version <> ".0"
      3 -> version
      _ -> raise("invalid version #{inspect(version)}")
    end
  end
end
