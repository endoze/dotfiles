{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    tmux
  ];

  # Unlinked while trying OpenRig: its agents run on the default tmux server,
  # which would load this config (reattach-to-user-namespace, continuum restore).
  # xdg.configFile = {
  #   "tmux".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/tmux";
  # };
}
