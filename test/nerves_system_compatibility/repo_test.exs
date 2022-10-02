defmodule NervesSystemCompatibility.ReoiTest do
  use ExUnit.Case
  alias NervesSystemCompatibility.Repo

  test "download_nerves_system_repo/1" do
    assert_raise(RuntimeError, fn ->
      Repo.download_nerves_system_repo("invalid_repo")
    end)
  end

  test "get_nerves_system_target_versions/1" do
    result = Repo.get_nerves_system_target_versions([:bbb, :rpi0])
    assert %{bbb: _, rpi0: _} = result

    assert is_list(result[:bbb])
    assert length(result[:bbb]) == 50
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

  test "normalize_version/1" do
    assert Repo.normalize_version("25") == "25.0.0"
    assert Repo.normalize_version("25.0") == "25.0.0"
    assert Repo.normalize_version("25.0.0") == "25.0.0"
    assert_raise(ArgumentError, fn -> Repo.normalize_version("") end)
    assert_raise(ArgumentError, fn -> Repo.normalize_version("invalid") end)
    assert_raise(RuntimeError, fn -> Repo.normalize_version("25.0.0.0") end)
  end
end
