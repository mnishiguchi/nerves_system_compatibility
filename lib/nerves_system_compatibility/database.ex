defmodule NervesSystemCompatibility.Database do
  @default_data_dir "_nerves_system_info"

  defstruct data_dir: @default_data_dir

  def get(%{data_dir: data_dir}, path) do
    value_location = Path.join(data_dir, path)

    if File.exists?(value_location) do
      case File.ls!(value_location) do
        [] -> nil
        [value] -> value
      end
    end
  end

  def put(%{data_dir: data_dir}, path, value) do
    Path.join([data_dir, path, to_string(value)]) |> File.mkdir_p!()
  end

  def delete(%{data_dir: data_dir}, path) do
    File.rm_rf!(Path.join(data_dir, path))
    :ok
  end

  def if_not_exists(db, path, fun) do
    if get(db, path) in [nil, ""], do: fun.()
  end

  defmodule NervesSystemTarget do
    alias NervesSystemCompatibility.API
    alias NervesSystemCompatibility.Database
    alias NervesSystemCompatibility.Linux

    def for_all_versions(fun) do
      for {target, versions} <- API.get_nerves_system_target_versions(), version <- versions do
        fun.(target, version)
      end
    end

    def get(db) do
      for_all_versions(fn target, version -> get(db, target, version) end)
    end

    def get(db, target, version) do
      %{
        target: target,
        version: version,
        linux_version: get_linux_version(db, target, version),
        nerves_system_br_version: get_nerves_system_br_version(db, target, version)
      }
    end

    defp linux_version_key(target, version) do
      Path.join(["nerves_system_#{target}", version, "linux_version"])
    end

    def get_linux_version(db, target, version) do
      key = linux_version_key(target, version)
      Database.get(db, key)
    end

    def update_linux_version(db, target, version) do
      key = linux_version_key(target, version)

      Database.if_not_exists(db, key, fn ->
        task = Task.async(Linux, :kernel_version, [target, version])
        linux_version = Task.await(task, :infinity)
        Database.put(db, key, linux_version || :unknown)
      end)
    end

    def update_linux_versions(db) do
      for_all_versions(fn target, version -> update_linux_version(db, target, version) end)
      :ok
    end

    defp nerves_system_br_version_key(target, version) do
      Path.join(["nerves_system_#{target}", version, "nerves_br_version"])
    end

    def get_nerves_system_br_version(db, target, version) do
      key = nerves_system_br_version_key(target, version)
      Database.get(db, key)
    end

    def update_nerves_system_br_version(db, target, version) do
      key = nerves_system_br_version_key(target, version)

      Database.if_not_exists(db, key, fn ->
        value = API.get_nerves_br_version_for_target(target, version)
        Database.put(db, key, value || :unknown)
      end)
    end

    def update_nerves_system_br_versions(db) do
      for_all_versions(fn target, version ->
        update_nerves_system_br_version(db, target, version)
      end)

      :ok
    end
  end

  defmodule NervesSystemBr do
    alias NervesSystemCompatibility.API
    alias NervesSystemCompatibility.Database

    def for_all_versions(fun) do
      for v <- API.get_nerves_system_br_versions(), do: fun.(v)
    end

    def get(db), do: for_all_versions(fn version -> get(db, version) end)

    def get(db, nerves_system_br_version) do
      %{
        version: nerves_system_br_version,
        buildroot_version: get_buildroot_version(db, nerves_system_br_version),
        otp_version: get_otp_version(db, nerves_system_br_version)
      }
    end

    def update(db) do
      for_all_versions(fn version ->
        update_buildroot_version(db, version)
        update_otp_version(db, version)
      end)

      :ok
    end

    def update(db, nerves_system_br_version) do
      update_buildroot_version(db, nerves_system_br_version)
      update_otp_version(db, nerves_system_br_version)
    end

    defp buildroot_version_key(nerves_system_br_version)
         when is_binary(nerves_system_br_version) do
      Path.join(["nerves_system_br", nerves_system_br_version, "buildroot_version"])
    end

    def get_buildroot_version(db, nerves_system_br_version) do
      key = buildroot_version_key(nerves_system_br_version)
      Database.get(db, key)
    end

    def update_buildroot_version(db, nerves_system_br_version) do
      key = buildroot_version_key(nerves_system_br_version)

      Database.if_not_exists(db, key, fn ->
        value = API.get_buildroot_version(nerves_system_br_version)
        Database.put(db, key, value || :unknown)
      end)
    end

    defp otp_version_key(nerves_system_br_version) when is_binary(nerves_system_br_version) do
      Path.join(["nerves_system_br", nerves_system_br_version, "otp_version"])
    end

    def get_otp_version(db, nerves_system_br_version) do
      key = otp_version_key(nerves_system_br_version)
      Database.get(db, key)
    end

    def update_otp_version(db, nerves_system_br_version) do
      key = otp_version_key(nerves_system_br_version)

      Database.if_not_exists(db, key, fn ->
        value = API.get_otp_version(nerves_system_br_version)
        Database.put(db, key, value || :unknown)
      end)
    end
  end
end
