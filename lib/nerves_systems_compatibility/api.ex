defmodule NervesSystemsCompatibility.API do
  @moduledoc false

  @spec fetch_nerves_br_versions! :: [binary]
  def fetch_nerves_br_versions! do
    fetch_package_versions!("nerves_system_br", requirement: ">= 1.14.0")
  end

  @spec fetch_nerves_system_versions! :: keyword([binary])
  def fetch_nerves_system_versions! do
    NervesSystemsCompatibility.target_systems()
    |> Task.async_stream(&{&1, fetch_nerves_system_versions!(&1)}, timeout: 10_000)
    |> Enum.reduce([], fn {:ok, kv}, acc -> [kv | acc] end)
  end

  @spec fetch_nerves_system_versions!(binary | atom) :: [binary]
  def fetch_nerves_system_versions!(target) do
    fetch_package_versions!("nerves_system_#{target}")
  end

  defp fetch_package_versions!(project_name, opts \\ []) do
    per_page = opts[:per_page] || 50
    requirement = opts[:requirement] || ">= 0.1.0"
    url = "https://api.github.com/repos/nerves-project/#{project_name}/tags?per_page=#{per_page}"

    %{status: 200, body: tags} =
      if token = Application.get_env(:nerves_systems_compatibility, :github_api_token) do
        Req.get!(url, headers: [Authorization: "token #{token}"], cache: true)
      else
        Req.get!(url, cache: true)
      end

    for %{"name" => "v" <> version} <- tags, Version.match?(version, requirement) do
      version
    end
    |> Enum.sort(Version)
  end

  @spec fetch_buildroot_version!(binary) :: %{binary => binary}
  def fetch_buildroot_version!(nerves_br_version) do
    %{status: 200, body: create_build_content} =
      Req.get!(
        "https://raw.githubusercontent.com/nerves-project/nerves_system_br/v#{nerves_br_version}/create-build.sh",
        cache: true
      )

    Regex.named_captures(
      ~r/NERVES_BR_VERSION=(?<buildroot_version>[0-9.]*)/,
      create_build_content,
      include_captures: true
    )
    |> Enum.into(%{"nerves_br_version" => nerves_br_version})
  end

  @spec fetch_otp_version!(binary) :: %{binary => binary}
  def fetch_otp_version!(nerves_br_version) do
    %{status: 200, body: tool_versions_content} =
      Req.get!(
        "https://raw.githubusercontent.com/nerves-project/nerves_system_br/v#{nerves_br_version}/.tool-versions",
        cache: true
      )

    Regex.named_captures(
      ~r/erlang (?<otp_version>[0-9.]*)/,
      tool_versions_content,
      include_captures: true
    )
    |> Enum.into(%{"nerves_br_version" => nerves_br_version})
  end

  @spec fetch_nerves_br_version_for_target!(binary | atom, binary) :: %{binary => binary}
  def fetch_nerves_br_version_for_target!(target, target_version) do
    %{status: 200, body: mix_lock_content} =
      Req.get!(
        "https://raw.githubusercontent.com/nerves-project/nerves_system_#{target}/v#{target_version}/mix.lock",
        cache: true
      )

    Regex.named_captures(
      ~r/:hex, :nerves_system_br, "(?<nerves_br_version>[0-9.]*)"/,
      mix_lock_content,
      include_captures: true
    )
    |> Enum.into(%{"target" => target, "target_version" => target_version})
  end
end
