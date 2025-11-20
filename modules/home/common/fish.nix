{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    fish
  ];

  xdg.configFile = {
    "fish".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/fish";
  };
}
