defmodule NervesSystemCompatibility.UtilsTest do
  use ExUnit.Case
  alias NervesSystemCompatibility.Utils
  doctest NervesSystemCompatibility.Utils

  test "normalize_version/1" do
    assert Utils.normalize_version("25") == "25.0.0"
    assert Utils.normalize_version("25.0") == "25.0.0"
    assert Utils.normalize_version("25.0.0") == "25.0.0"
    assert_raise(ArgumentError, fn -> Utils.normalize_version("") end)
    assert_raise(ArgumentError, fn -> Utils.normalize_version("invalid") end)
    assert_raise(RuntimeError, fn -> Utils.normalize_version("25.0.0.0") end)
  end
end
