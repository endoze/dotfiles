{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    tmux
  ];

  home.file = {
    ".tmux.conf".source = "${sourceRoot}/config/tmux.conf";
  };

  xdg.configFile = {
    "tmux".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/tmux";
  };
}
