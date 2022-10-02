defmodule NervesSystemCompatibility.Database do
  alias NervesSystemCompatibility.Repo

  def init, do: :ets.new(__MODULE__, [:set, :named_table])

  def get(key, default \\ nil) do
    case :ets.lookup(__MODULE__, key) do
      [] -> default
      [{_, value} | _rest] -> value
    end
  end

  def put(key, value), do: :ets.insert(__MODULE__, [{key, value}])

  def build do
    nerves_system_br_versions = Repo.get_nerves_system_br_versions()
    put({:br, :versions}, nerves_system_br_versions)

    for target <- NervesSystemCompatibility.nerves_targets() do
      versions = Repo.get_nerves_system_versions(target)
      put({target, :versions}, versions)

      for version <- versions do
        put(
          {target, version, :nerves_system_br_version},
          Repo.get_nerves_system_br_version_for_target(target, version)
        )

        put(
          {target, version, :nerves_version},
          Repo.get_nerves_version_for_target(target, version)
        )

        put(
          {target, version, :linux_version},
          Repo.get_linux_version_for_target(target, version)
        )

        IO.write(".")
      end
    end

    for nerves_system_br_version <- nerves_system_br_versions do
      put(
        {:br, nerves_system_br_version, :buildroot_version},
        Repo.get_buildroot_version(nerves_system_br_version)
      )

      put(
        {:br, nerves_system_br_version, :otp_version},
        Repo.get_otp_version(nerves_system_br_version)
      )

      IO.write(".")
    end

    IO.write("\n")
  end
end
