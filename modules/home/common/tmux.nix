{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    tmux
  ];

  xdg.configFile = {
    "tmux".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/tmux";
  };
}
