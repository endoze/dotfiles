{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    tmux
  ];

  home.file = {
    ".tmux.conf".source = "${sourceRoot}/config/tmux.conf";
  };

  xdg.configFile = {
    "tmux".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/tmux";
  };
}
