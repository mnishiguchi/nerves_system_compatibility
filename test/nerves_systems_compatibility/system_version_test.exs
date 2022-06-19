defmodule NervesSystemsCompatibility.SystemVersionTest do
  use ExUnit.Case, async: true

  import NervesSystemsCompatibility.SystemVersion

  test "otp_versions/0" do
    result = otp_versions()

    assert is_list(result)
  end

  test "nerves_system_versions/0" do
    result = nerves_system_versions()

    assert is_list(result)
    assert Keyword.fetch!(result, :rpi0) |> is_list()
  end

  test "nerves_system_versions/1" do
    result = nerves_system_versions(:bbb)

    assert is_list(result)
  end

  test "file_path_to_existing_target_system_atom/1" do
    assert file_path_to_existing_target_system_atom(
             Path.join([
               :code.priv_dir(:nerves_systems_compatibility),
               "versions",
               "nerves_system_bbb"
             ])
           ) == :bbb

    assert_raise(RuntimeError, fn -> file_path_to_existing_target_system_atom("invalid") end)
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
