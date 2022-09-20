defmodule NervesSystemCompatibility.ReoiTest do
  use ExUnit.Case
  alias NervesSystemCompatibility.Repo

  test "download_nerves_system_repo/1" do
    assert {:error, _} = Repo.download_nerves_system_repo("invalid_repo")
  end

  test "download_dir/0" do
    assert Repo.download_dir() == "tmp/data/repos"
  end

  test "nerves_system_repo_dir/1" do
    assert Repo.nerves_system_repo_dir(:rpi0) == "tmp/data/repos/nerves_system_rpi0"
    assert Repo.nerves_system_repo_dir(:bbb) == "tmp/data/repos/nerves_system_bbb"
  end

  test "get_nerves_system_target_versions/1" do
    result = Repo.get_nerves_system_target_versions([:bbb, :rpi0])
    assert %{bbb: _, rpi0: _} = result

    assert [
             "2.15.2",
             "2.15.1",
             "2.15.0",
             "2.14.0",
             "2.13.4",
             "2.13.3",
             "2.13.2",
             "2.13.1",
             "2.13.0",
             "2.12.3",
             "2.12.2",
             "2.12.1",
             "2.12.0",
             "2.11.2",
             "2.11.1",
             "2.11.0",
             "2.10.1",
             "2.10.0",
             "2.9.0",
             "2.8.3"
             | _rest
           ] = result[:bbb]
  end

  test "get_nerves_system_br_versions_for_targets/1" do
    assert %{
             {:bbb, "2.12.3"} => "1.17.4",
             {:bbb, "2.13.0"} => "1.18.2",
             {:bbb, "2.13.1"} => "1.18.3",
             {:bbb, "2.13.2"} => "1.18.4",
             {:bbb, "2.13.3"} => "1.18.5",
             {:bbb, "2.13.4"} => "1.18.6",
             {:bbb, "2.14.0"} => "1.19.0",
             {:bbb, "2.15.0"} => "1.20.3",
             {:bbb, "2.15.1"} => "1.20.3",
             {:bbb, "2.15.2"} => "1.20.4",
             {:rpi0, "1.17.2"} => "1.17.3",
             {:rpi0, "1.17.3"} => "1.17.4",
             {:rpi0, "1.18.0"} => "1.18.2",
             {:rpi0, "1.18.1"} => "1.18.3",
             {:rpi0, "1.18.2"} => "1.18.4",
             {:rpi0, "1.18.3"} => "1.18.5",
             {:rpi0, "1.18.4"} => "1.18.6",
             {:rpi0, "1.19.0"} => "1.19.0",
             {:rpi0, "1.20.0"} => "1.20.3",
             {:rpi0, "1.20.1"} => "1.20.4"
           } = Repo.get_nerves_system_br_versions_for_targets([:bbb, :rpi0])
  end

  test "get_buildroot_version/1" do
    assert Repo.get_buildroot_version("1.20.0") == "2022.05"
  end

  test "get_otp_version/1" do
    assert Repo.get_otp_version("1.20.0") == "25.0.1"
    assert Repo.get_otp_version("1.12.0") == "23.0.2"
    assert Repo.get_otp_version("1.11.4") == "22.3.4"
    assert Repo.get_otp_version("1.4.1") == "21.0"
    assert Repo.get_otp_version("0.16.2") == "20.2.1"
    assert Repo.get_otp_version("0.2.3") == "17.5"
  end

  test "get_linux_version_for_target/2" do
    assert Repo.get_linux_version_for_target(:rpi, "1.20.0") == "5.15"
  end
end
