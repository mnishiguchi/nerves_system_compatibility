defmodule NervesSystemCompatibility.Database do
  @database_dir "tmp/data"

  def open do
    File.mkdir_p(@database_dir)
    db_file = "#{@database_dir}/dets.db" |> to_charlist()
    :dets.open_file(__MODULE__, file: db_file, type: :set)
  end

  def get(key, default \\ nil) do
    case :dets.lookup(__MODULE__, key) do
      [] -> default
      [{_, value} | _rest] -> value
    end
  end

  def put(key, value) do
    :dets.insert(__MODULE__, [{key, value}])
  end
end
