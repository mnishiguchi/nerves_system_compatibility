defmodule NervesSystemsCompatibilityTest do
  use ExUnit.Case
  doctest NervesSystemsCompatibility

  test "versions" do
    result = NervesSystemsCompatibility.versions()

    assert is_map(result)
    assert is_list(result[:rpi0])
  end

  test "get" do
    result = NervesSystemsCompatibility.get()

    assert is_list(result)

    assert %{
             "buildroot" => "2020.08",
             "nerves_br" => "1.13.2",
             "otp" => "23.1.1",
             "target" => {:rpi, "1.13.0"}
           } in result
  end

  test "targets" do
    result = NervesSystemsCompatibility.targets()

    assert is_list(result)
    assert :rpi0 in result
  end
end
