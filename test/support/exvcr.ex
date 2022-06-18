defmodule NervesSystemsCompatibility.TestHelper.ExVCR do
  @vcr_dir "test/vcr_cassettes"

  def set_vcr_dir(_) do
    ExVCR.Config.cassette_library_dir(@vcr_dir)
    :ok
  end

  def cassette_name(%{file: file, test: test}) do
    case_name = Path.basename(file, ".exs")
    Path.join(case_name, to_string(test))
  end
end
