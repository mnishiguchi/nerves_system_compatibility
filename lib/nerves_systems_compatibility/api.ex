defmodule NervesSystemsCompatibility.API do
  @moduledoc false

  @spec fetch_buildroot_version!(binary) :: %{binary => binary}
  def fetch_buildroot_version!(nerves_br_version) do
    %{status: 200, body: create_build_content} =
      Req.get!(
        "https://raw.githubusercontent.com/nerves-project/nerves_system_br/v#{nerves_br_version}/create-build.sh"
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
        "https://raw.githubusercontent.com/nerves-project/nerves_system_br/v#{nerves_br_version}/.tool-versions"
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
        "https://raw.githubusercontent.com/nerves-project/nerves_system_#{target}/v#{target_version}/mix.lock"
      )

    Regex.named_captures(
      ~r/:hex, :nerves_system_br, "(?<nerves_br_version>[0-9.]*)"/,
      mix_lock_content,
      include_captures: true
    )
    |> Enum.into(%{"target" => target, "target_version" => target_version})
  end
end
