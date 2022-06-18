defmodule NervesSystemsCompatibility.DataTest do
  use ExUnit.Case
  alias NervesSystemsCompatibility.Data

  test "get_data" do
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

  test "group_data_by_otp_and_target" do
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
