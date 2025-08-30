{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    fish
  ];

  xdg.configFile = {
    "fish".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/fish";
  };
}
