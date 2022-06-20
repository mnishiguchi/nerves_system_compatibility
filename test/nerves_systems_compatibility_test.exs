defmodule NervesSystemsCompatibilityTest do
  use ExUnit.Case

  import NervesSystemsCompatibility

  test "otp_versions/0" do
    result = otp_versions()

    assert is_list(result)
  end
end
