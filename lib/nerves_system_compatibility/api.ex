defmodule NervesSystemCompatibility.API do
  @moduledoc """
  Functions that fetch various info from Github repos.
  The results is cached.
  """

  @github_api_req Req.new(base_url: "https://api.github.com", cache: true)
  @github_raw_req Req.new(base_url: "https://raw.githubusercontent.com", cache: true)

  @spec get_nerves_system_br_versions :: [binary]
  def get_nerves_system_br_versions(opts \\ []) do
    get_package_versions("nerves_system_br", opts)
  end

  def get_nerves_system_target_versions(target \\ :all, opts \\ [])

  @spec get_nerves_system_target_versions(atom, keyword) :: keyword([binary])
  def get_nerves_system_target_versions(:all, opts) do
    NervesSystemCompatibility.target_systems()
    |> Enum.reduce([], fn target, acc ->
      [{target, get_nerves_system_target_versions(target, opts)} | acc]
    end)
  end

  @spec get_nerves_system_target_versions(binary | atom, keyword) :: [binary]
  def get_nerves_system_target_versions(target, opts) do
    get_package_versions("nerves_system_#{target}", opts)
  end

  defp get_package_versions(project_name, opts) do
    requirement = opts[:requirement] || ">= 0.1.0"
    url = "repos/nerves-project/#{project_name}/git/refs/tags"

    case Req.get!(@github_api_req, url: url, headers: github_api_headers()) do
      %{status: 200, body: tags} ->
        for %{"ref" => "refs/tags/v" <> version} <- tags, Version.match?(version, requirement) do
          version
        end
        # Remove x.x.x-rc1 etc
        |> Enum.filter(&String.match?(&1, ~r/^(\d+)\.(\d+)\.(\d+)$/))
        |> Enum.sort(Version)

      _ ->
        []
    end
  end

  @spec get_buildroot_version(binary) :: binary | nil
  def get_buildroot_version(nerves_br_version) do
    if buildroot_version = get_buildroot_version_from_create_build(nerves_br_version) do
      buildroot_version
    else
      case get_github_release(:br, nerves_br_version) do
        %{"body" => body} -> scan_github_release_body(body).buildroot_version
        _ -> nil
      end
    end
  end

  defp get_buildroot_version_from_create_build(nerves_br_version) do
    url = "nerves-project/nerves_system_br/v#{nerves_br_version}/create-build.sh"

    case Req.get!(@github_raw_req, url: url) do
      %{status: 200, body: create_build_content} ->
        captures =
          Regex.named_captures(
            ~r/NERVES_BR_VERSION=(?<buildroot_version>[0-9.]*)/,
            create_build_content
          )

        captures["buildroot_version"]

      _ ->
        nil
    end
  end

  @spec get_otp_version(binary) :: binary | nil
  def get_otp_version(nerves_br_version) do
    cond do
      Version.match?(nerves_br_version, ">= 1.12.0") ->
        get_otp_version_from_tool_versions(nerves_br_version)

      Version.match?(nerves_br_version, ">= 1.7.3") ->
        get_otp_version_from_dockerfile(nerves_br_version)

      Version.match?(nerves_br_version, ">= 0.2.3") ->
        get_otp_version_from_patch(nerves_br_version)

      true ->
        nil
    end
  end

  def get_otp_version_from_patch(nerves_br_version) do
    url =
      "repos/nerves-project/nerves_system_br/git/trees/v#{nerves_br_version}?recursive=1"

    case Req.get!(@github_api_req, url: url, headers: github_api_headers()) do
      %{status: 200, body: %{"tree" => tree}} ->
        joint_paths =
          tree
          |> Enum.map(fn x -> x["path"] end)
          |> Enum.filter(fn x -> x =~ ~r/(erlang|otp).*\.patch/i end)
          |> Enum.join("\n")

        captures =
          Regex.named_captures(
            ~r/(erlang|otp).*-(?<otp_version>(\d+\.)?(\d+\.)?(\d+)).patch/i,
            joint_paths
          )

        if captures, do: captures["otp_version"]

      _ ->
        nil
    end
  end

  def get_otp_version_from_dockerfile(nerves_br_version) do
    path =
      cond do
        Version.match?(nerves_br_version, "> 1.4.0") ->
          "support/docker/nerves_system_br/Dockerfile"

        Version.match?(nerves_br_version, ">= 0.16.2") ->
          "support/docker/nerves/Dockerfile"

        true ->
          raise "no dockerfile before 0.16.2"
      end

    url = "nerves-project/nerves_system_br/v#{nerves_br_version}/#{path}"

    case Req.get!(@github_raw_req, url: url) do
      %{status: 200, body: dockerfile_content} ->
        captures =
          [
            Regex.named_captures(
              ~r/FROM hexpm\/erlang\:(?<otp_version>(\d+\.)?(\d+\.)?(\*|\d+))/i,
              dockerfile_content
            ),
            Regex.named_captures(
              ~r/ERLANG_OTP_VERSION=(?<otp_version>(\d+\.)?(\d+\.)?(\*|\d+))/i,
              dockerfile_content
            )
          ]
          |> Enum.reject(&is_nil/1)
          |> List.first()

        if captures, do: captures["otp_version"]

      _ ->
        nil
    end
  end

  def get_otp_version_from_tool_versions(nerves_br_version) do
    url = "nerves-project/nerves_system_br/v#{nerves_br_version}/.tool-versions"

    with %{status: 200, body: tool_versions_content} <- Req.get!(@github_raw_req, url: url),
         %{"otp_version" => otp_version} <-
           Regex.named_captures(
             ~r/erlang (?<otp_version>[0-9.]*)/,
             tool_versions_content
           ) do
      otp_version
    else
      _ ->
        nil
    end
  end

  def scan_github_release_body(%{"body" => body}), do: scan_github_release_body(body)

  def scan_github_release_body(github_release_body) do
    captures =
      [
        Regex.named_captures(
          ~r/Buildroot (?<buildroot_version>(\d+\.)?(\d+\.)?(\*|\d+))/i,
          github_release_body
        ),
        Regex.named_captures(
          ~r/(Erlang\/OTP|erlang) (?<otp_version>(\d+\.)?(\d+\.)?(\*|\d+))/i,
          github_release_body
        ),
        Regex.named_captures(
          ~r/(Linux) (?<linux_version>(\d+\.)?(\d+\.)?(\*|\d+))/i,
          github_release_body
        )
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce(%{}, fn x, acc -> Enum.into(x, acc) end)

    %{
      buildroot_version: captures["buildroot_version"],
      otp_version: captures["otp_version"],
      linux_version: captures["linux_version"]
    }
  end

  @spec get_nerves_br_version_for_target(binary | atom, binary) :: binary | nil
  def get_nerves_br_version_for_target(target, target_version) do
    url = "nerves-project/nerves_system_#{target}/v#{target_version}/mix.lock"

    with %{status: 200, body: mix_lock_content} <- Req.get!(@github_raw_req, url: url),
         %{"nerves_br_version" => nerves_br_version} <-
           Regex.named_captures(
             ~r/:hex, :nerves_system_br, "(?<nerves_br_version>[0-9.]*)"/,
             mix_lock_content
           ) do
      nerves_br_version
    else
      _ ->
        nil
    end
  end

  @spec get_linux_version_for_target(binary | atom, binary) :: binary | nil
  def get_linux_version_for_target(target, target_version) do
    url = "nerves-project/nerves_system_#{target}/v#{target_version}/nerves_defconfig"

    case Req.get!(@github_raw_req, url: url) do
      %{status: 200, body: defconfig_content} ->
        captures =
          [
            Regex.named_captures(
              ~r/BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="(?<linux_version>(\d+\.)?(\d+\.)?(\*|\d+))"/i,
              defconfig_content
            ),
            Regex.named_captures(
              ~r/linux-(?<linux_version>(\d+\.)?(\d+\.)?(\*|\d+))\.defconfig/i,
              defconfig_content
            )
          ]
          |> Enum.reject(&is_nil/1)
          |> List.first()

        if captures, do: captures["linux_version"]

      _ ->
        nil
    end
  end

  def get_github_release(target, version \\ nil) do
    tag = if version, do: "v#{version}", else: :latest
    url = "repos/nerves-project/nerves_system_#{target}/releases/tags/#{tag}"

    case Req.get!(@github_api_req, url: url, headers: github_api_headers()) do
      %{status: 200, body: github_release} -> github_release
      _ -> nil
    end
  end

  def get_github_releases(target) do
    url = "repos/nerves-project/nerves_system_#{target}/releases"

    case Req.get!(@github_api_req, url: url, headers: github_api_headers()) do
      %{status: 200, body: github_releases} -> github_releases
      nil -> nil
    end
  end

  defp github_api_headers do
    if token = Application.get_env(:nerves_system_compatibility, :github_api_token) do
      [{:Authorization, "token #{token}"}]
    else
      []
    end
  end
end
