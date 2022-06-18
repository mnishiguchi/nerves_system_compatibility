defmodule NervesSystemsCompatibilityTest do
  use ExUnit.Case
  doctest NervesSystemsCompatibility

  test "otp_versions/0" do
    result = NervesSystemsCompatibility.otp_versions()

    assert is_list(result)
  end

  test "nerves_system_versions/0" do
    result = NervesSystemsCompatibility.nerves_system_versions()

    assert is_list(result)
    assert is_list(result[:rpi0])
  end

  test "nerves_system_versions/1" do
    result = NervesSystemsCompatibility.nerves_system_versions(:bbb)

    assert is_list(result)
  end

  test "targets/0" do
    result = NervesSystemsCompatibility.targets()

    assert is_list(result)
    assert :rpi0 in result
    assert :br not in result
    assert :otp not in result
  end
end
