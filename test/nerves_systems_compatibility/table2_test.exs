defmodule NervesSystemsCompatibility.Table2Test do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch
  alias NervesSystemsCompatibility.Data

  test "build_table" do
    use_cassette "api_test" do
      compatibility_data = Data.get()
      data_by_system_version = Data.group_data_by_target(compatibility_data)[:bbb]
      system_versions = Data.list_target_system_versions(compatibility_data, :bbb)

      result =
        NervesSystemsCompatibility.Table2.build(:bbb, data_by_system_version, system_versions)

      assert result ==
               """
               | nerves_system_bbb  | Erlang/OTP         | nerves_system_br   | Buildroot          |
               | ---                | ---                | ---                | ---                |
               | 2.14.0             | 25.0               | 1.19.0             | 2022.02.1          |
               | 2.13.4             | 24.3.2             | 1.18.6             | 2021.11.2          |
               | 2.13.3             | 24.2.2             | 1.18.5             | 2021.11.2          |
               | 2.13.2             | 24.2               | 1.18.4             | 2021.11.1          |
               | 2.13.1             | 24.2               | 1.18.3             | 2021.11            |
               | 2.13.0             | 24.2               | 1.18.2             | 2021.11            |
               | 2.12.3             | 24.1.7             | 1.17.4             | 2021.08.2          |
               | 2.12.2             | 24.1.4             | 1.17.3             | 2021.08.1          |
               | 2.12.1             | 24.1.2             | 1.17.1             | 2021.08.1          |
               | 2.12.0             | 24.1               | 1.17.0             | 2021.08            |
               | 2.11.2             | 24.0.5             | 1.16.4             | 2021.05.1          |
               | 2.11.1             | 24.0.2             | 1.16.1             | 2021.05            |
               | 2.11.0             | 24.0.2             | 1.16.0             | 2021.05            |
               | 2.10.1             | 23.3.1             | 1.15.1             | 2021.02.1          |
               | 2.10.0             | 23.2.7             | 1.15.0             | 2021.02            |
               | 2.9.0              | 23.2.4             | 1.14.4             | 2020.11.2          |
               """
               |> String.trim()
    end
  end
end
