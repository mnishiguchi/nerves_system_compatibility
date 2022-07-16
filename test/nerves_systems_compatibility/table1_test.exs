defmodule NervesSystemsCompatibility.Table1Test do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch
  alias NervesSystemsCompatibility.Data

  test "build_table" do
    use_cassette "api_test" do
      compatibility_data = Data.get()
      result = NervesSystemsCompatibility.Table1.build(compatibility_data)

      assert result ==
               """
               |            | bbb      | osd32mp1 | rpi      | rpi0     | rpi2     | rpi3     | rpi3a    | rpi4     | x86_64   |
               | ---        | ---      | ---      | ---      | ---      | ---      | ---      | ---      | ---      | ---      |
               | OTP 25.0   | 2.14.0   | 0.10.0   | 1.19.0   | 1.19.0   | 1.19.0   | 1.19.0   | 1.19.0   | 1.19.0   | 1.19.0   |
               | OTP 24.3.2 | 2.13.4   | 0.9.4    | 1.18.4   | 1.18.4   | 1.18.4   | 1.18.4   | 1.18.4   | 1.18.4   | 1.18.4   |
               | OTP 24.2.2 | 2.13.3   | 0.9.3    | 1.18.3   | 1.18.3   | 1.18.3   | 1.18.3   | 1.18.3   | 1.18.3   | 1.18.3   |
               | OTP 24.2   | 2.13.2   | 0.9.2    | 1.18.2   | 1.18.2   | 1.18.2   | 1.18.2   | 1.18.2   | 1.18.2   | 1.18.2   |
               | OTP 24.1.7 | 2.12.3   | 0.8.3    | 1.17.3   | 1.17.3   | 1.17.3   | 1.17.4   | 1.17.3   | 1.17.3   | 1.17.3   |
               | OTP 24.1.4 | 2.12.2   | 0.8.2    | 1.17.2   | 1.17.2   | 1.17.2   | 1.17.3   | 1.17.2   | 1.17.2   | 1.17.2   |
               | OTP 24.1.2 | 2.12.1   | 0.8.1    | 1.17.1   | 1.17.1   | 1.17.1   | 1.17.2   | 1.17.1   | 1.17.1   | 1.17.1   |
               | OTP 24.1   | 2.12.0   | 0.8.0    | 1.17.0   | 1.17.0   | 1.17.0   | 1.17.1   | 1.17.0   | 1.17.0   | 1.17.0   |
               | OTP 24.0.5 | 2.11.2   | 0.7.2    | 1.16.2   | 1.16.2   | 1.16.2   | 1.16.2   | 1.16.2   | 1.16.3   | 1.16.2   |
               | OTP 24.0.2 | 2.11.1   | 0.7.1    | 1.16.1   | 1.16.1   | 1.16.1   | 1.16.1   | 1.16.1   | 1.16.1   | 1.16.1   |
               | OTP 23.3.1 | 2.10.1   | 0.6.1    | 1.15.1   | 1.15.1   | 1.15.1   | 1.15.1   | 1.15.1   | 1.15.1   | 1.15.1   |
               | OTP 23.2.7 | 2.10.0   | 0.6.0    | 1.15.0   | 1.15.0   | 1.15.0   | 1.15.0   | 1.15.0   | 1.15.0   | 1.15.0   |
               | OTP 23.2.4 | 2.9.0    | 0.5.0    | 1.14.1   | 1.14.1   | 1.14.0   | 1.14.0   | 1.14.0   | 1.14.0   | 1.14.0   |
               """
               |> String.trim()
    end
  end
end