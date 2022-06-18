defmodule NervesSystemsCompatibility.TestHelper.ExVCR do
  @moduledoc false

  @default_vcr_dir "test/vcr_cassettes"

  @doc """
  Sets up VCR and imports helper functions.

  ## Examples

      use #{__MODULE__}

  """
  defmacro __using__(opts \\ []) do
    vcr_dir = opts[:vcr_dir] || @default_vcr_dir

    quote do
      use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

      setup do
        ExVCR.Config.cassette_library_dir(unquote(vcr_dir))
        :ok
      end

      @doc """
      Returns a cassette name for the test context.
      """
      def cassette_name(%{file: file, test: test} = _context) do
        case_name = Path.basename(file, ".exs")
        Path.join(case_name, to_string(test))
      end
    end
  end
end
