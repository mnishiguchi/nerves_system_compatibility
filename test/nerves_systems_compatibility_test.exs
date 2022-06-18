defmodule NervesSystemsCompatibilityTest do
  use ExUnit.Case
  doctest NervesSystemsCompatibility

  test "versions" do
    result = NervesSystemsCompatibility.versions()

    assert is_map(result)
    assert is_list(result[:rpi0])
  end

  test "targets" do
    result = NervesSystemsCompatibility.targets()

    assert is_list(result)
    assert :rpi0 in result
    assert :br not in result
    assert :otp not in result
  end
end
