defmodule NervesSystemsCompatibility.Version.VersionTest do
  use ExUnit.Case, async: true

  import NervesSystemsCompatibility.Version

  test "otp_versions/0" do
    result = otp_versions()

    assert is_list(result)
  end

  test "nerves_system_versions/0" do
    result = nerves_system_versions()

    assert is_list(result)
    assert is_list(result[:rpi0])
  end

  test "nerves_system_versions/1" do
    result = nerves_system_versions(:bbb)

    assert is_list(result)
  end

  test "targets/0" do
    result = targets()

    assert is_list(result)
    assert :rpi0 in result
    assert :br not in result
    assert :otp not in result
  end

  test "normalize_version/1" do
    assert normalize_version("25") == "25.0.0"
    assert normalize_version("25.0") == "25.0.0"
    assert normalize_version("25.0.0") == "25.0.0"
    assert_raise(ArgumentError, fn -> normalize_version("") end)
    assert_raise(ArgumentError, fn -> normalize_version("invalid") end)
    assert_raise(RuntimeError, fn -> normalize_version("25.0.0.0") end)
  end
end
