defmodule NervesSystemsCompatibilityTest do
  use ExUnit.Case
  doctest NervesSystemsCompatibility

  test "versions" do
    result = NervesSystemsCompatibility.versions()
    IO.inspect(result)

    assert is_map(result)
    assert is_list(result[:rpi0])
  end

  test "get" do
    result = NervesSystemsCompatibility.get()
    IO.inspect(result)

    assert is_map(result)
    assert is_map(result[:rpi0])

    assert get_in(result, [:rpi0, "1.19.0"]) == %{
             "buildroot" => "2022.02.1",
             "nerves_br" => "1.19.0",
             "otp" => "25.0"
           }
  end
end
