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

  test "group_data_by_target" do
    use_cassette "api_test" do
      grouped_data = Data.get() |> Data.group_data_by_target()

      assert is_map(grouped_data)

      assert get_in(grouped_data, [:x86_64, "1.14.0"]) ==
               %{
                 "buildroot_version" => "2020.11.2",
                 "nerves_br_version" => "1.14.4",
                 "otp_version" => "23.2.4",
                 "target" => :x86_64,
                 "target_version" => "1.14.0"
               }
    end
  end

  test "list_target_system_versions/2" do
    use_cassette "api_test" do
      compatibility_data = Data.get()

      assert Data.list_target_system_versions(compatibility_data, :bbb) == [
               "2.14.0",
               "2.13.4",
               "2.13.3",
               "2.13.2",
               "2.13.1",
               "2.13.0",
               "2.12.3",
               "2.12.2",
               "2.12.1",
               "2.12.0",
               "2.11.2",
               "2.11.1",
               "2.11.0",
               "2.10.1",
               "2.10.0",
               "2.9.0"
             ]
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
