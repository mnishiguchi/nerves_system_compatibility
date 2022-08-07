defmodule NervesSystemCompatibility.LinuxTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch
  alias NervesSystemCompatibility.Linux

  @moduletag timeout: :infinity

  def cassette_name(context), do: "linux_test/#{context.test}"

  test "kernel_version/2", context do
    use_cassette cassette_name(context) do
      assert Linux.kernel_version(:rpi0, "1.19.0") == "5.10.88"
    end
  end
end
