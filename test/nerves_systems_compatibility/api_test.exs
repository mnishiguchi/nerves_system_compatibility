defmodule NervesSystemsCompatibility.APITest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch
  alias NervesSystemsCompatibility.API

  test "fetch_nerves_br_versions!/0" do
    use_cassette "api_test" do
      result = API.fetch_nerves_br_versions!()

      assert result == [
               "1.14.0",
               "1.14.1",
               "1.14.2",
               "1.14.3",
               "1.14.4",
               "1.14.5",
               "1.15.0",
               "1.15.1",
               "1.15.2",
               "1.16.0",
               "1.16.1",
               "1.16.2",
               "1.16.3",
               "1.16.4",
               "1.16.5",
               "1.17.0",
               "1.17.1",
               "1.17.2",
               "1.17.3",
               "1.17.4",
               "1.18.0",
               "1.18.1",
               "1.18.2",
               "1.18.3",
               "1.18.4",
               "1.18.5",
               "1.18.6",
               "1.19.0",
               "1.19.1",
               "1.20.0",
               "1.20.1"
             ]
    end
  end

  test "fetch_nerves_system_versions!/0" do
    use_cassette "api_test" do
      result = API.fetch_nerves_system_versions!()

      assert result[:bbb] == [
               "1.1.0",
               "1.1.1",
               "1.2.0",
               "1.2.1",
               "1.3.0",
               "1.4.0",
               "2.0.0-rc.0",
               "2.0.0",
               "2.1.0",
               "2.1.1",
               "2.1.2",
               "2.1.3",
               "2.2.0",
               "2.2.1",
               "2.2.2",
               "2.3.0",
               "2.3.1",
               "2.3.2",
               "2.4.0",
               "2.4.1",
               "2.4.2",
               "2.5.0",
               "2.5.1",
               "2.5.2",
               "2.6.0",
               "2.6.1",
               "2.6.2",
               "2.7.0",
               "2.7.1",
               "2.7.2",
               "2.8.0",
               "2.8.1",
               "2.8.2",
               "2.8.3",
               "2.9.0",
               "2.10.0",
               "2.10.1",
               "2.11.0",
               "2.11.1",
               "2.11.2",
               "2.12.0",
               "2.12.1",
               "2.12.2",
               "2.12.3",
               "2.13.0",
               "2.13.1",
               "2.13.2",
               "2.13.3",
               "2.13.4",
               "2.14.0"
             ]
    end
  end

  test "fetch_nerves_system_versions!/1" do
    use_cassette "api_test" do
      result = API.fetch_nerves_system_versions!(:bbb)

      assert result == [
               "1.1.0",
               "1.1.1",
               "1.2.0",
               "1.2.1",
               "1.3.0",
               "1.4.0",
               "2.0.0-rc.0",
               "2.0.0",
               "2.1.0",
               "2.1.1",
               "2.1.2",
               "2.1.3",
               "2.2.0",
               "2.2.1",
               "2.2.2",
               "2.3.0",
               "2.3.1",
               "2.3.2",
               "2.4.0",
               "2.4.1",
               "2.4.2",
               "2.5.0",
               "2.5.1",
               "2.5.2",
               "2.6.0",
               "2.6.1",
               "2.6.2",
               "2.7.0",
               "2.7.1",
               "2.7.2",
               "2.8.0",
               "2.8.1",
               "2.8.2",
               "2.8.3",
               "2.9.0",
               "2.10.0",
               "2.10.1",
               "2.11.0",
               "2.11.1",
               "2.11.2",
               "2.12.0",
               "2.12.1",
               "2.12.2",
               "2.12.3",
               "2.13.0",
               "2.13.1",
               "2.13.2",
               "2.13.3",
               "2.13.4",
               "2.14.0"
             ]
    end
  end

  test "fetch_buildroot_version!" do
    use_cassette "api_test" do
      result = API.fetch_buildroot_version!("1.20.0")

      assert result == %{
               "buildroot_version" => "2022.05",
               "nerves_br_version" => "1.20.0"
             }
    end
  end

  test "fetch_otp_version!" do
    use_cassette "api_test" do
      result = API.fetch_otp_version!("1.20.0")

      assert result == %{
               "otp_version" => "25.0.1",
               "nerves_br_version" => "1.20.0"
             }
    end
  end

  test "fetch_nerves_br_version_for_target!" do
    use_cassette "api_test" do
      result = API.fetch_nerves_br_version_for_target!(:rpi0, "1.19.0")

      assert result == %{
               "target" => :rpi0,
               "nerves_br_version" => "1.19.0",
               "target_version" => "1.19.0"
             }
    end
  end
end
