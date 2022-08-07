defmodule NervesSystemCompatibility.APITest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  alias NervesSystemCompatibility.API

  @moduletag timeout: :infinity

  def cassette_name(context), do: "api_test/#{context.test}"

  test "get_nerves_system_br_versions/0", context do
    use_cassette cassette_name(context) do
      result = API.get_nerves_system_br_versions(requirement: ">= 1.11.0")

      assert result == [
               "1.11.0",
               "1.11.1",
               "1.11.2",
               "1.11.3",
               "1.11.4",
               "1.12.0",
               "1.12.1",
               "1.12.2",
               "1.12.3",
               "1.12.4",
               "1.13.0",
               "1.13.1",
               "1.13.2",
               "1.13.3",
               "1.13.4",
               "1.13.5",
               "1.13.6",
               "1.13.7",
               "1.13.8",
               "1.14.0",
               "1.14.1",
               "1.14.2",
               "1.14.3",
               "1.14.4",
               "1.14.5",
               "1.15.0",
               "1.15.1",
               "1.15.2",
               "1.16.0",
               "1.16.1",
               "1.16.2",
               "1.16.3",
               "1.16.4",
               "1.16.5",
               "1.17.0",
               "1.17.1",
               "1.17.2",
               "1.17.3",
               "1.17.4",
               "1.18.0",
               "1.18.1",
               "1.18.2",
               "1.18.3",
               "1.18.4",
               "1.18.5",
               "1.18.6",
               "1.19.0",
               "1.19.1",
               "1.20.0",
               "1.20.1",
               "1.20.2",
               "1.20.3",
               "1.20.4"
             ]
    end
  end

  test "get_nerves_system_target_versions/0", context do
    use_cassette cassette_name(context) do
      result = API.get_nerves_system_target_versions(:all, requirement: ">= 2.10.0")

      assert result[:bbb] == [
               "2.10.0",
               "2.10.1",
               "2.11.0",
               "2.11.1",
               "2.11.2",
               "2.12.0",
               "2.12.1",
               "2.12.2",
               "2.12.3",
               "2.13.0",
               "2.13.1",
               "2.13.2",
               "2.13.3",
               "2.13.4",
               "2.14.0",
               "2.15.0",
               "2.15.1"
             ]
    end
  end

  test "get_nerves_system_target_versions/1", context do
    use_cassette cassette_name(context) do
      result = API.get_nerves_system_target_versions(:bbb, requirement: ">= 2.10.0")

      assert result == [
               "2.10.0",
               "2.10.1",
               "2.11.0",
               "2.11.1",
               "2.11.2",
               "2.12.0",
               "2.12.1",
               "2.12.2",
               "2.12.3",
               "2.13.0",
               "2.13.1",
               "2.13.2",
               "2.13.3",
               "2.13.4",
               "2.14.0",
               "2.15.0",
               "2.15.1"
             ]
    end
  end

  test "get_buildroot_version", context do
    use_cassette cassette_name(context) do
      result = API.get_buildroot_version("1.20.0")

      assert result == "2022.05"
    end
  end

  test "get_otp_version", context do
    use_cassette cassette_name(context) do
      result = API.get_otp_version("1.20.0")

      assert result == "25.0.1"
    end
  end

  test "get_nerves_br_version_for_target", context do
    use_cassette cassette_name(context) do
      result = API.get_nerves_br_version_for_target(:rpi0, "1.19.0")

      assert result == "1.19.0"
    end
  end

  test "get_github_release", context do
    use_cassette cassette_name(context) do
      assert %{"assets" => assets} = API.get_github_release(:rpi0, "1.19.0")

      assert [
               %{
                 "content_type" => "application/gzip",
                 "name" => "nerves_system_rpi0-portable-1.19.0-E128A3B.tar.gz",
                 "browser_download_url" =>
                   "https://github.com/nerves-project/nerves_system_rpi0/releases/download/v1.19.0/nerves_system_rpi0-portable-1.19.0-E128A3B.tar.gz"
               }
             ] = assets
    end
  end

  test "get_github_releases", context do
    use_cassette cassette_name(context) do
      [first | _rest] = API.get_github_releases(:bbb)

      assert Map.keys(first) == [
               "assets",
               "assets_url",
               "author",
               "body",
               "created_at",
               "draft",
               "html_url",
               "id",
               "name",
               "node_id",
               "prerelease",
               "published_at",
               "tag_name",
               "tarball_url",
               "target_commitish",
               "upload_url",
               "url",
               "zipball_url"
             ]
    end
  end
end
