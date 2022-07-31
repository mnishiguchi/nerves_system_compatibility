defmodule NervesSystemCompatibility.Linux do
  @moduledoc false

  alias NervesSystemCompatibility.API

  @tmp_dir "tmp/nerves_artifacts"

  @doc """
  Returns linux kernel version for a Nerves system
  """
  @spec kernel_version(atom, String.t()) :: String.t() | nil
  def kernel_version(target, version) do
    release = API.get_github_release(target, version)

    get_kernel_verson(release["assets"]) ||
      get_kernel_verson(target, version) ||
      get_kernel_verson(release["body"])
  rescue
    _e -> nil
  end

  # This is least reliable because of being hand-written
  defp get_kernel_verson(github_release_body) when is_binary(github_release_body) do
    API.scan_github_release_body(github_release_body).linux_version
  end

  defp get_kernel_verson(
         [
           %{
             "content_type" => "application/gzip",
             "name" => archive_file,
             "browser_download_url" => archive_src_url
           }
         ] = _github_release_assets
       ) do
    get_kernel_verson(archive_src_url, archive_file)
  end

  defp get_kernel_verson(_), do: nil

  defp get_kernel_verson(target, version) when is_atom(target) and is_binary(version) do
    API.get_linux_version_for_target(target, version)
  end

  defp get_kernel_verson(artifact_src_url, artifact_file) do
    artifact_dest = "#{@tmp_dir}/#{String.trim_trailing(artifact_file, ".tar.gz")}"

    if !File.exists?(artifact_dest) do
      # Download artifact, decompress and save to tmp dir
      %{status: 200, body: compressed_data} = Req.get!(artifact_src_url)
      :erl_tar.extract({:binary, compressed_data}, [:compressed, {:cwd, @tmp_dir}])
    end

    with {rootfs_fs_list_data, 0} <-
           System.cmd("unsquashfs", ["-l", "#{artifact_dest}/images/rootfs.squashfs"]),
         %{"kernel_version" => kernel_version} <-
           Regex.named_captures(
             ~r{squashfs-root/lib/modules/(?<kernel_version>[0-9]+\.[0-9]+\.[0-9]+).*},
             rootfs_fs_list_data
           ) do
      File.rm_rf!(artifact_dest)
      kernel_version
    else
      _ ->
        File.rm_rf!(artifact_dest)
        nil
    end
  end
end
