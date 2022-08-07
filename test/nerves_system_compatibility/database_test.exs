defmodule NervesSystemCompatibility.DatabaseTest do
  use ExUnit.Case, async: true

  alias NervesSystemCompatibility.Database

  @tag :tmp_dir
  test "put, get and delete", context do
    db = %{data_dir: context.tmp_dir}

    assert :ok = Database.put(db, "test/a/b/c", "1")
    assert Database.get(db, "test/a/b/c") == "1"

    assert :ok = Database.delete(db, "test/a/b/c")
    assert Database.get(db, "test/a/b/c") |> is_nil()
  end
end
