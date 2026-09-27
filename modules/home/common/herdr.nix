{ config, pkgs, lib, inputs, userConfig, ... }:

{
  home.packages = [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Out-of-store, matching pi.nix: a manifest edit takes effect on the next
  # `herdr server reload-agent-manifests` rather than a rebuild. A single file
  # rather than the directory, because everything else under ~/.config/herdr
  # (config.toml, plugins/, session.json, the sockets and logs) is written by
  # herdr itself and must stay writable.
  home.file.".config/herdr/agent-detection/pi.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${userConfig.dotfilesPath}/config/herdr/agent-detection/pi.toml";
}
