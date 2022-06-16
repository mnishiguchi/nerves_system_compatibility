defmodule NervesSystemsCompatibility.Repo do
  def get_system_br_metadata!(system_br_version) do
    %{status: 200, body: create_build_content} =
      Req.get!(
        "https://raw.githubusercontent.com/nerves-project/nerves_system_br/v#{system_br_version}/create-build.sh"
      )

    %{status: 200, body: tool_versions_content} =
      Req.get!(
        "https://raw.githubusercontent.com/nerves-project/nerves_system_br/v#{system_br_version}/.tool-versions"
      )

    %{"nerves_br" => system_br_version}
    |> Map.merge(
      Regex.named_captures(
        ~r/NERVES_BR_VERSION=(?<buildroot>[0-9.]*)/,
        create_build_content,
        include_captures: true
      )
    )
    |> Map.merge(
      Regex.named_captures(
        ~r/erlang (?<otp>[0-9.]*)/,
        tool_versions_content,
        include_captures: true
      )
    )
  end

  def get_system_br_version_for_target!(target, tag) do
    %{status: 200, body: mix_lock_content} =
      Req.get!(
        "https://raw.githubusercontent.com/nerves-project/nerves_system_#{target}/v#{tag}/mix.lock"
      )

    Regex.named_captures(
      ~r/:hex, :nerves_system_br, "(?<nerves_br>[0-9.]*)"/,
      mix_lock_content,
      include_captures: true
    )
    |> Access.fetch!("nerves_br")
  end
end
