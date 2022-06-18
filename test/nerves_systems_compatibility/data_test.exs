defmodule NervesSystemsCompatibility.DataTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch
  import NervesSystemsCompatibility.TestHelper.ExVCR

  alias NervesSystemsCompatibility.Data

  setup [:set_vcr_dir]

  test "get_data", context do
    use_cassette cassette_name(context) do
      result = Data.get()

      assert is_list(result)

      assert %{
               "buildroot_version" => "2020.08",
               "nerves_br_version" => "1.13.2",
               "otp_version" => "23.1.1",
               "target_version" => "1.13.0",
               "target" => :rpi
             } in result
    end
  end

  test "group_data_by_otp_and_target", context do
    use_cassette cassette_name(context) do
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
end
