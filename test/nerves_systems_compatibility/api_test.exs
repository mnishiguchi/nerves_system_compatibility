defmodule NervesSystemsCompatibility.APITest do
  use ExUnit.Case

  test "fetch_buildroot_version!" do
    result = NervesSystemsCompatibility.API.fetch_buildroot_version!("1.20.0")
    assert result == %{"buildroot" => "2022.05"}
  end

  test "fetch_otp_version!" do
    result = NervesSystemsCompatibility.API.fetch_otp_version!("1.20.0")
    assert result == %{"otp" => "25.0.1"}
  end

  test "fetch_nerves_br_version_for_target!" do
    result = NervesSystemsCompatibility.API.fetch_nerves_br_version_for_target!(:rpi0, "1.19.0")
    assert result == "1.19.0"
  end
end
