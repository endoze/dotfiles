{ config, pkgs, lib, inputs, userConfig, ... }:

{
  home.packages = [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Out-of-store, matching pi.nix: a manifest edit takes effect on the next
  # `herdr server reload-agent-manifests` rather than a rebuild. Single files
  # rather than the directory, because everything else under ~/.config/herdr
  # (plugins/, session.json, the sockets and logs) is runtime state written by
  # herdr itself. config.toml must stay writable too: the settings overlay and
  # onboarding write keys back through the symlink into the repo.
  home.file.".config/herdr/agent-detection/pi.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${userConfig.dotfilesPath}/config/herdr/agent-detection/pi.toml";

  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${userConfig.dotfilesPath}/config/herdr/config.toml";
}
