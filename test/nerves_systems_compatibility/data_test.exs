defmodule NervesSystemsCompatibility.DataTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  alias NervesSystemsCompatibility.Data

  test "get" do
    use_cassette "api_test" do
      result = Data.get()

      assert is_list(result)

      assert %{
               "buildroot_version" => "2022.02.1",
               "nerves_br_version" => "1.19.0",
               "otp_version" => "25.0",
               "target" => :x86_64,
               "target_version" => "1.19.0"
             } in result
    end
  end

  test "group_data_by_otp_and_target" do
    use_cassette "api_test" do
      grouped_data = Data.get() |> Data.group_data_by_otp_and_target()

      assert is_map(grouped_data)

      assert get_in(grouped_data, ["25.0", :x86_64]) ==
               %{
                 "buildroot_version" => "2022.02.1",
                 "nerves_br_version" => "1.19.0",
                 "otp_version" => "25.0",
                 "target" => :x86_64,
                 "target_version" => "1.19.0"
               }
    end
  end

  test "normalize_version/1" do
    assert Data.normalize_version("25") == "25.0.0"
    assert Data.normalize_version("25.0") == "25.0.0"
    assert Data.normalize_version("25.0.0") == "25.0.0"
    assert_raise(ArgumentError, fn -> Data.normalize_version("") end)
    assert_raise(ArgumentError, fn -> Data.normalize_version("invalid") end)
    assert_raise(RuntimeError, fn -> Data.normalize_version("25.0.0.0") end)
  end
end
